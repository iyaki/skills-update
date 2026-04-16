import fs from "node:fs";

const COVERAGE_PATH = "coverage/coverage-summary.json";
const minimumCoverage = Number(process.env.COVERAGE_MIN ?? 99);

function fail(message) {
  console.error(`[coverage] ${message}`);
  process.exit(1);
}

if (!Number.isFinite(minimumCoverage)) {
  fail("invalid COVERAGE_MIN value");
}

if (!fs.existsSync(COVERAGE_PATH)) {
  fail(`missing ${COVERAGE_PATH}; run the coverage script first`);
}

const summary = JSON.parse(fs.readFileSync(COVERAGE_PATH, "utf8"));
const totalLineCoverage = Number(summary?.total?.lines?.pct);

if (!Number.isFinite(totalLineCoverage)) {
  fail("could not read total line coverage from coverage summary");
}

if (totalLineCoverage < minimumCoverage) {
  fail(`coverage ${totalLineCoverage}% is below required ${minimumCoverage}%`);
}

console.log(`[coverage] ok ${totalLineCoverage}% >= ${minimumCoverage}%`);
