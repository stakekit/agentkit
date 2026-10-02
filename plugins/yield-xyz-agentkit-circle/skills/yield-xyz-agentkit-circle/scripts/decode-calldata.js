#!/usr/bin/env node

/**
 * Decode a Yield.xyz unsignedTransaction's raw calldata into the ABI function
 * signature + typed argument list that Circle's `circle wallet execute` requires.
 *
 * Circle's agent wallet signer has no "pass raw calldata" option — it only accepts a
 * human-readable function signature and positional arguments. This script bridges
 * that gap: it is a lossless, VERIFIED format conversion, never a best-effort guess.
 *
 * A decode is only trusted once it round-trips: the decoded signature + args are
 * re-encoded and compared byte-for-byte against the original calldata. If nothing
 * verifies, the script reports verified: false and callers MUST NOT proceed to sign.
 *
 * Usage:
 *   node decode-calldata.js '<unsignedTransaction JSON>'
 *   echo '<unsignedTransaction JSON>' | node decode-calldata.js -
 *
 * Output (stdout, JSON):
 *   { verified: true,  selector, signature, args, source, to, value }
 *   { verified: false, selector, candidatesTried, reason }
 *
 * Exit code: 0 if verified, 1 otherwise. Callers must check this before signing.
 */

const { ethers } = require("ethers");
const { whatsabi } = require("@shazow/whatsabi");

// Selectors verified against real keccak256(signature) — see
// references/calldata-decoder.md for how to regenerate/extend this table. This is
// a cache, not a ceiling: anything not listed here falls through to the public
// signature-lookup step below.
const KNOWN_SIGNATURES = {
  // ERC-20
  "0x095ea7b3": "approve(address,uint256)",
  "0xa9059cbb": "transfer(address,uint256)",
  "0x23b872dd": "transferFrom(address,address,uint256)",

  // ERC-4626 — covers any compliant vault, including Fluid and Morpho's
  // MetaMorpho vaults (Morpho's main "earn" product)
  "0x6e553f65": "deposit(uint256,address)",
  "0x94bf804d": "mint(uint256,address)",
  "0xb460af94": "withdraw(uint256,address,address)",
  "0xba087652": "redeem(uint256,address,address)",

  // Aave V3 Pool (also Spark, and other Aave-V3 forks sharing this ABI)
  "0x617ba037": "supply(address,uint256,address,uint16)",
  "0x69328dec": "withdraw(address,uint256,address)",
  "0x573ade81": "repay(address,uint256,uint256,address)",

  // Compound V3 (Comet)
  "0xf2b9fdb8": "supply(address,uint256)",
  "0xf3fef3a3": "withdraw(address,uint256)",

  // Morpho Blue — direct market functions (not the MetaMorpho vault wrapper
  // above). MarketParams is (loanToken,collateralToken,oracle,irm,lltv).
  "0xa99aad89":
    "supply((address,address,address,address,uint256),uint256,uint256,address,bytes)",
  "0x5c2bea49":
    "withdraw((address,address,address,address,uint256),uint256,uint256,address,address)",
  "0x238d6579":
    "supplyCollateral((address,address,address,address,uint256),uint256,address,bytes)",
  "0x8720316d":
    "withdrawCollateral((address,address,address,address,uint256),uint256,address,address)",
  "0x50d8cd4b":
    "borrow((address,address,address,address,uint256),uint256,uint256,address,address)",
  "0x20b76e81":
    "repay((address,address,address,address,uint256),uint256,uint256,address,bytes)",

  // Compound V2-style cTokens — Compound V2 itself, Venus, and other forks
  // that still use this older single-uint256-arg pattern
  "0xa0712d68": "mint(uint256)",
  "0xdb006a75": "redeem(uint256)",
  "0x852a12e3": "redeemUnderlying(uint256)",
  "0xc5ebeaec": "borrow(uint256)",
  "0x0e752702": "repayBorrow(uint256)",
  "0x2608f818": "repayBorrowBehalf(address,uint256)",

  // Lido
  "0xa1903eab": "submit(address)",
};

function readStdin() {
  return new Promise((resolve, reject) => {
    let data = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (chunk) => (data += chunk));
    process.stdin.on("end", () => resolve(data));
    process.stdin.on("error", reject);
  });
}

// Does this function have any non-primitive (tuple/struct or array) parameter?
// Circle's `circle wallet execute --help` only documents plain scalar examples
// (address, uintN, bool, bytesN, string) — there is no documented syntax for
// passing a struct or array as a single CLI argument. Stringifying one with
// Array.prototype.toString() (comma-joining, no brackets, no nesting) is NOT
// verified to be what `circle wallet execute` expects.
function hasStructOrArrayArg(fragment) {
  return fragment.inputs.some((input) => input.baseType === "tuple" || input.baseType === "array");
}

// Try to decode `data` against one candidate signature, verifying by round-trip
// re-encoding. Returns { args, hasStructOrArrayArg } on success, or null if this
// candidate doesn't verify (wrong signature, wrong types, or a decode error).
function tryCandidate(signature, data) {
  try {
    const iface = new ethers.Interface(["function " + signature]);
    const fragment = iface.getFunction(signature);
    const decoded = iface.decodeFunctionData(fragment, data);
    const reEncoded = iface.encodeFunctionData(fragment, decoded);
    if (reEncoded.toLowerCase() !== data.toLowerCase()) return null;
    return { args: decoded.map(String), hasStructOrArrayArg: hasStructOrArrayArg(fragment) };
  } catch {
    return null;
  }
}

// Heuristic only — used purely to choose a nicer display name among candidates that
// already produce byte-identical calldata. Never affects what gets signed.
function pickMostReadable(candidates) {
  const looksAutoGenerated = (name) => /^[a-z]+\d{4,}$/i.test(name) || /^func_?0x/i.test(name);
  const ranked = [...candidates].sort((a, b) => {
    const aName = a.signature.split("(")[0];
    const bName = b.signature.split("(")[0];
    const aBad = looksAutoGenerated(aName) ? 1 : 0;
    const bBad = looksAutoGenerated(bName) ? 1 : 0;
    if (aBad !== bBad) return aBad - bBad;
    return aName.length - bName.length;
  });
  return ranked[0];
}

function structArgWarning(result) {
  if (!result.hasStructOrArrayArg) return {};
  return {
    needsManualArgFormatCheck: true,
    structArgWarning:
      "This function takes a struct or array argument. `args` shows it as a plain " +
      "comma-joined string (e.g. a tuple's fields with no brackets) — this has NOT " +
      "been confirmed to be the syntax `circle wallet execute` expects for a " +
      "non-scalar argument; the CLI's own --help only documents scalar examples. " +
      "Before broadcasting: run the same command with --estimate first (fee " +
      "estimate only, does not broadcast) and confirm it accepts the argument " +
      "as given. If it errors or you're unsure, stop and ask the user, or use " +
      "the Privy/MoonPay connector for this transaction instead.",
  };
}

async function lookupCandidates(selector) {
  // 4byte.directory has proven reliable in testing; OpenChain is included as a
  // second source. MultiSignatureLookup tolerates one provider failing as long as
  // another succeeds, and de-dupes across sources.
  const lookup = new whatsabi.loaders.MultiSignatureLookup([
    new whatsabi.loaders.FourByteSignatureLookup(),
    new whatsabi.loaders.OpenChainSignatureLookup(),
  ]);
  try {
    return await lookup.loadFunctions(selector);
  } catch {
    return [];
  }
}

async function main() {
  const rawArg = process.argv[2];
  if (!rawArg) {
    console.error(
      "Usage: node decode-calldata.js '<unsignedTransaction JSON>' | node decode-calldata.js -"
    );
    process.exit(2);
  }

  const raw = rawArg === "-" ? await readStdin() : rawArg;
  const tx = JSON.parse(raw);

  if (!tx.data || tx.data === "0x") {
    console.log(
      JSON.stringify(
        { verified: false, reason: "unsignedTransaction has no calldata to decode (a plain value transfer needs no ABI call)" },
        null,
        2
      )
    );
    process.exit(1);
  }

  const selector = tx.data.slice(0, 10).toLowerCase();
  const candidatesTried = [];

  // Step 1 — known table (still verified, never trusted blindly — see tryCandidate).
  if (KNOWN_SIGNATURES[selector]) {
    const sig = KNOWN_SIGNATURES[selector];
    candidatesTried.push({ signature: sig, source: "known-table" });
    const result = tryCandidate(sig, tx.data);
    if (result) {
      console.log(
        JSON.stringify(
          {
            verified: true,
            selector,
            signature: sig,
            args: result.args,
            source: "known-table",
            to: tx.to,
            value: tx.value ?? "0",
            ...structArgWarning(result),
          },
          null,
          2
        )
      );
      process.exit(0);
    }
  }

  // Step 2 — public signature-lookup fallback. These are untrusted candidates —
  // every one still has to pass the round-trip check before being trusted.
  //
  // A 4-byte selector is only 32 bits, so two *different* function signatures can
  // genuinely collide (e.g. mint(address,uint256) and a meaningless auto-generated
  // name can share a selector). When that happens, every colliding candidate with
  // matching argument types round-trips to the exact same calldata — so it does not
  // matter *which* one is passed to `circle wallet execute`, the on-chain call is
  // byte-identical either way. Collect every verified candidate, report the
  // collision if there is one, and prefer the most human-readable name for clarity.
  const candidates = await lookupCandidates(selector);
  const verifiedCandidates = [];
  for (const sig of candidates) {
    candidatesTried.push({ signature: sig, source: "public-lookup" });
    const result = tryCandidate(sig, tx.data);
    if (result) verifiedCandidates.push({ signature: sig, args: result.args });
  }

  if (verifiedCandidates.length > 0) {
    const chosen = pickMostReadable(verifiedCandidates);
    console.log(
      JSON.stringify(
        {
          verified: true,
          selector,
          signature: chosen.signature,
          args: chosen.args,
          source: "public-lookup",
          to: tx.to,
          value: tx.value ?? "0",
          ...structArgWarning(chosen),
          ...(verifiedCandidates.length > 1
            ? {
                selectorCollision: true,
                collisionNote:
                  "Multiple registered signatures share this 4-byte selector. All of them round-trip to byte-identical calldata, so the on-chain call is the same regardless of which is used — the most readable name was chosen for display.",
                otherVerifiedSignatures: verifiedCandidates
                  .filter((c) => c.signature !== chosen.signature)
                  .map((c) => c.signature),
              }
            : {}),
        },
        null,
        2
      )
    );
    process.exit(0);
  }

  // Nothing verified. Do not guess — report failure so the caller stops.
  console.log(
    JSON.stringify(
      {
        verified: false,
        selector,
        candidatesTried,
        reason:
          candidatesTried.length === 0
            ? "no known or publicly-registered function signature found for this selector"
            : "one or more candidate signatures were found, but none round-tripped back to the exact original calldata",
      },
      null,
      2
    )
  );
  process.exit(1);
}

main().catch((err) => {
  console.log(JSON.stringify({ verified: false, reason: `decoder error: ${err.message}` }, null, 2));
  process.exit(1);
});
