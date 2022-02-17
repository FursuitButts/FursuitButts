import { existsSync, readFileSync, writeFileSync } from "fs";

if(!existsSync(`${__dirname}/old`)) writeFileSync(`${__dirname}/old`, "");

function flatten<T = unknown>(a: Array<T>, b: Array<T>) { return a.concat(b); }

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
	"brown",
	"multicolored",
	"two_tone",
	"rainbow",
	"monotone"
];
const genericColors = [
	"multicolored",
	"two_tone",
	"monotone"
];
const nonGenericColors = colors.filter(color => !genericColors.includes(color));

const genders = [
	"male",
	"female",
	"gynomorph",
	"andromorph",
	"herm",
	"maleherm",
    "intersex"
];
const nonIntersexGenders = ["male", "female"];
const intersexGenders = genders.filter(g => !nonIntersexGenders.includes(g));

const genderStuff: Array<string> = [], genderProcessed: Array<string> = [];
for(const g of genders) {
	for(const g2 of genders) {
        if(genderProcessed.includes(`${g2}/${g}`)) {
            genderStuff.push(`alias ${g}/${g2} -> ${g2}/${g}`);
            continue;
        }
        genderProcessed.push(`${g}/${g2}`);
        if(g === g2 || (g2 === "intersex" && intersexGenders.includes(g))) genderStuff.push(`imply ${g}/${g2} -> ${g}`);
        else genderStuff.push(`imply ${g}/${g2} -> ${g}`, `imply ${g}/${g2} -> ${g2}`);
	}
}

const penetrationStuff: Array<string> = [];
for(const g of genders) {
	for(const g2 of genders) penetrationStuff.push(`imply ${g}_penetrating_${g2} -> ${g}_penetrating`, `imply ${g}_penetrating_${g2} -> ${g2}_penetrated`);
	penetrationStuff.push(`imply ${g}_penetrating -> ${g}`, `imply ${g}_penetrated -> ${g}`);
}
const colored: Array<string> = [], coloredProcessed: Array<string> = [];
const coloredClothing = [
	"stockings",
	"arm_warmers",
	"t-shirt",
	"shirt",
	"shorts"
]
for(const piece of coloredClothing) {
	for(const color of nonGenericColors) {
        colored.push(`imply ${color}_${piece} -> ${piece}`, `imply striped_${piece} -> striped_clothing`);
		for(const c2 of nonGenericColors) {
			if(coloredProcessed.includes(`${c2}_and_${color}_${piece}`)) {
				colored.push(`alias ${color}_and_${c2}_${piece} -> ${c2}_and_${color}_${piece}`);
				continue;
			}
        	coloredProcessed.push(`${color}_and_${c2}_${piece}`);
			if(color === c2) colored.push(`alias ${color}_and_${color}_${piece} -> ${color}_${piece}`);
       		else colored.push(`imply ${color}_and_${c2}_${piece} -> ${color}_${piece}`, `imply ${color}_and_${c2}_${piece} -> ${c2}_${piece}`, `imply ${color}_and_${c2}_${piece} -> striped_${piece}`);
		}
	}
}
console.log(coloredProcessed);

const bur = [
	"alias femboy -> girly",
	"imply dildo -> sex_toy",
	"imply dildo_in_ass -> sex_toy_in_ass",
	"imply sex_toy_in_ass -> sex_toy",
	"imply sex_toy_in_ass -> anal_penetration",
	"imply dildo_in_ass -> dildo_insertion",
	"imply dildo_insertion -> sex_toy_insertion",
	"imply sex_toy_insertion -> sex_toy",
	"imply vibrator -> sex_toy",
	"imply vibrator_on_penis -> vibrator",
	"imply vibrator_on_penis -> penis",
	"imply vibrator_in_anus -> vibrator",
	"imply vibrator_in_anus -> sex_toy_in_anus",
	"alias barely_visible_genitals -> barely_visible_genitalia",
	"imply barely_visible_genitalia -> genitals",
	"imply saliva_string -> bodily_fluids",
	"imply bone_gag -> gag",
	"imply ankle_cuffs -> cuff_(restraint)",
	"imply wrist_cuffs -> cuff_(restraint)",
	"imply knotting -> knot",

	// species
	"imply wolf -> canid",
	"imply canine -> canid",

	// cum
	"imply cum_in_ass -> cum",
	"imply cum_on_ass -> cum",
	"imply cum_on_clothing -> cum",

	// clothing
	"imply garter -> accessory",
	"imply clothed -> clothing",
	"imply boy_shorts -> clothing",
	"imply tight_clothing -> clothing",
	"imply bottomless -> clothed",
	"imply topless -> clothed",
	"imply striped_clothing -> clothing",
	"imply panties -> clothing",
	"imply translucent_panties -> panties",
	"imply translucent_panties -> translucent",
	...colored,

	// gender
	"imply gynomorph -> intersex",
	"imply andromorph -> intersex",
	"imply herm -> intersex",
	"imply maleherm -> intersex",
	...genderStuff,
	
	// bulge
	"alias penis_bulge -> bulge",
	"imply balls_outline -> detailed_bulge",
	"imply balls_outline -> genital_outline",
	"imply penis_outline -> detailed_bulge",
	"imply penis_outline -> genital_outline",
	"imply detailed_bulge -> bulge",
	"imply presenting_bulge -> bulge",
	"imply presenting_bulge -> presenting",

	// penetration
	"imply anal_penetration -> penetration",
	"imply anal_penetration -> anus",
	"imply anal -> anal_penetration",
	...penetrationStuff,

	// cum
	"imply precum -> genital_fluids",
	"imply cum -> genital_fluids",

	// camel toe
	"alias pussy_bulge -> camel_toe",
	"imply presenting_camel_toe -> camel_toe",
	"imply presenting_camel_toe -> presenting",

	// claws
	"imply toe_claws -> claws",
	...colors.map(color => [`imply ${color}_claws -> claws`]).reduce(flatten),

	// tongue
	"imply tongue_out -> tongue",
	"imply blep -> tongue_out",
	"imply licking_lips -> tongue_out",
	...colors.map(color => [`imply ${color}_tongue -> tongue`]).reduce(flatten),

	// collar
	...colors.map(color => [`imply ${color}_collar -> collar`]).reduce(flatten),

	// paws
	...colors.map(color => [`imply ${color}_pawpads -> pawpads`]).reduce(flatten),
	...["glowing", "pawpads", "bioluminescence"].map(val => `imply glowing_pawpads -> ${val}`),
	"imply pawpads -> paws",
	"imply presenting_paws -> paws",
	"imply presenting_paws -> presenting",
	"alias feet -> paws",
	"imply paw_focus -> paws",
	"alias foot_focus -> paw_focus",

	// anus
	"imply spreading_anus -> spreading",
	"imply x_anus -> anus",
	"alias x_butt -> x_anus",
	"imply multi_anus -> anus",
	...colors.map(color => [`imply ${color}_anus -> anus`]).reduce(flatten),
	...["glowing", "anus", "bioluminescence"].map(val => `imply glowing_anus -> ${val}`),
	...["barely_visible", "presenting", "spreading"].map(v => `imply ${v}_anus -> anus`),
	"imply presenting_anus -> presenting",

	// balls
	"imply balls -> genitals",
	"imply backsack -> balls",
	"imply barely_visible_balls -> barely_visible_genitalia",
	"alias ball_fondle -> ball_fondling",
	"alias ball_grab -> ball_grabbing",
	"alias ball_kiss -> ball_kissing",
	"alias ball_lick -> ball_licking",
	"alias ball_slap -> ball_slapping",
	"alias ball_sniff -> ball_sniffing",
	"alias ball_suck -> ball_fondling",
	"alias ballbusting -> ball_busting",
	"imply cum_on_balls -> cum",
	...colors.map(val => [`imply ${val}_balls -> balls`]).reduce(flatten),
	...["glowing", "balls", "bioluminescence"].map(val => `imply glowing_balls -> ${val}`),
	...["barely_visible", "presenting"].map(v => `imply ${v}_balls -> balls`),
	"imply presenting_balls -> presenting",

	// pussy
	"imply pussy -> genitals",
	"imply barely_visible_pussy -> barely_visible_genitalia",
	...colors.map(val => [`imply ${val}_pussy -> pussy`]).reduce(flatten),
	...["glowing", "pussy", "bioluminescence"].map(val => `imply glowing_pussy -> ${val}`),
	...["barely_visible", "presenting"].map(v => `imply ${v}_pussy -> pussy`),
	"imply presenting_pussy -> presenting",

	// penis
	"imply penis -> genitals",
	"imply barely_visible_penis -> barely_visible_genitalia",
	...colors.map(val => [`imply ${val}_penis -> penis`]).reduce(flatten),
	...["glowing", "penis", "bioluminescence"].map(val => `imply glowing_penis -> ${val}`),
	...["barely_visible", "presenting"].map(v => `imply ${v}_penis -> penis`),
	"imply presenting_penis -> presenting",
	"imply humanoid_penis -> humanoid_genitalia",
	"imply humanoid_genitalia -> genitals",
	"imply humanoid_penis -> penis",
	"imply erect_penis -> erection",
	"imply erect_penis -> penis",
	"imply canine_penis -> animal_genitalia",
	"imply canine_penis -> knot",
	"imply animal_genitalia -> genitals",
	"imply two_tone_penis -> penis",
	"imply multicolored_penis -> penis",
	"imply"

	// perineum
	...colors.map(val => [`imply ${val}_perineum -> perineum`]).reduce(flatten),
	...["glowing", "perineum", "bioluminescence"].map(val => `imply glowing_perineum -> ${val}`),
	...["barely_visible", "presenting"].map(v => `imply ${v}_perineum -> perineum`),
	"imply presenting_perineum -> presenting",

	// fur
	...colors.map(val => [`imply ${val}_fur -> ${val}_body`, `imply ${val}_fur -> fur`]).reduce(flatten),
	"imply glowing_fur -> fur",
	"imply glowing_fur -> glowing_body",
	"imply glowing_body -> glowing",
	"imply glowing_body -> bioluminescence",

	// hair
	...colors.map(val => [`imply ${val}_hair -> hair`]).reduce(flatten),
	...["glowing", "hair", "bioluminescence"].map(val => `imply glowing_hair -> ${val}`),

	// butt
	"imply presenting_butt -> presenting",
	"imply spreading_butt -> spreading",
	...["presenting", "spreading", "raised"].map(v => `imply ${v}_butt -> butt`)
];


const old = readFileSync(`${__dirname}/old`).toString().split("\n");
writeFileSync(`${__dirname}/old`, bur.filter(Boolean).join("\n"));
old.forEach(val => {
	if(bur.includes(val)) bur.splice(bur.indexOf(val), 1);
});
writeFileSync(`${__dirname}/new`, bur.filter(Boolean).join("\n"));

if(bur.filter(Boolean).length === 0) {
	console.log("Nothing New.");
	process.exit(0);
}
writeFileSync(`${__dirname}/new`, bur.filter(Boolean).join("\n"));

console.log(bur.join("\n").replace(/\n{2,}/g, "").trim());
