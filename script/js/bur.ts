import { existsSync, readFileSync, writeFileSync } from "fs";

if(!existsSync(`${__dirname}/old`)) writeFileSync(`${__dirname}/old`, "");
const bur: Array<string> = [];

/** Begin Colors */
const colors = [
	"blue",
	"black",
	"green",
	"orange",
	"pink",
	"purple",
	"red",
	"tan",
	"white",
	"yellow",
	"multicolored",
	"two_tone",
	"rainbow",
	"monotone"
];
// anus
colors.forEach(color => bur.push(`imply ${color}_anus -> anus`));
bur.push("");

// balls
colors.forEach(color => bur.push(`imply ${color}_balls -> balls`));
bur.push("");

// penis
colors.forEach(color => bur.push(`imply ${color}_penis -> penis`));
bur.push("");

// perineum
colors.forEach(color => bur.push(`imply ${color}_perineum -> perineum`));
bur.push("");

// fur
colors.forEach(color => bur.push(`imply ${color}_fur -> ${color}_body`, `imply ${color}_fur -> fur`));
bur.push("");

// hair
colors.forEach(color => bur.push(`imply ${color}_hair -> hair`));
bur.push("");

/** End Colors */

// glowing
["anus", "penis", "balls", "perineum", "fur", "hair"].forEach(val => bur.push(`imply glowing_${val} -> glowing`, `imply glowing_${val} -> ${val}`, `imply glowing_${val} -> bioluminescence`));
bur.push(
	"imply glowing_fur -> fur",
	"imply glowing_fur -> glowing_body",
	"imply glowing_body -> bioluminescence",
	""
);

// barely visible
["penis", "balls"].forEach(val => bur.push(`imply barely_visible_${val} -> ${val}`));
bur.push(
	`imply barely_visible_anus -> anus`,
	`imply barely_visible_perineum -> peineum`,
	""
);

// presenting & spread
["anus", "balls", "penis", "butt"].forEach(val => bur.push(`imply presenting_${val} -> presenting`, `imply presenting_${val} -> ${val}`, `imply spreading_${val} -> ${val}`));
bur.push("");

const old = readFileSync(`${__dirname}/old`).toString().split("\n");
writeFileSync(`${__dirname}/old`, bur.filter(Boolean).join("\n"));
old.forEach(val => {
	if(bur.includes(val)) bur.splice(bur.indexOf(val), 1);
});

if(bur.filter(Boolean).length === 0) {
	console.log("Nothing New.");
	process.exit(0);
}

console.log(bur.join("\n").replace(/\n{2,}/g, "").trim());
