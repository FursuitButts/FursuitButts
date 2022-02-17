import E621 from "e621";
import { enable } from "debug";
import { SYSTEM_TOKEN } from "./secrets";
const e = new E621.YiffyAPI({
	authUser: "System",
	authKey: SYSTEM_TOKEN
});

enable("e621:*");
process.nextTick(async() => {
	// Yiff -> Bulge (1)
	await e.postSets.create({
		name: "[API] Official Yiff -> Bulge",
		shortname: "official_yiff_bulge",
		description: "The official collection of bulge yiff posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));

	// Yiff -> Gay (2)
	await e.postSets.create({
		name: "[API] Official Yiff -> Gay",
		shortname: "official_yiff_gay",
		description: "The official collection of gay yiff posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Yiff -> Straight (3)
	await e.postSets.create({
		name: "[API] Official Yiff -> Straight",
		shortname: "official_yiff_straight",
		description: "The official collection of straight yiff posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Yiff -> Lesbian (4)
	await e.postSets.create({
		name: "[API] Official Yiff -> Lesbian",
		shortname: "official_yiff_lesbian",
		description: "The official collection of lesbian yiff posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Yiff -> Gynomorph (5)
	await e.postSets.create({
		name: "[API] Official Yiff -> Gynomorph",
		shortname: "official_yiff_gynomorph",
		description: "The official collection of gynomorph yiff posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Yiff -> Andromorph (6)
	await e.postSets.create({
		name: "[API] Official Yiff -> Andromorph",
		shortname: "official_yiff_andromorph",
		description: "The official collection of andromorph yiff posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Yiff -> Male-Solo (7)
	await e.postSets.create({
		name: "[API] Official Yiff -> Male-Solo",
		shortname: "official_yiff_male_solo",
		description: "The official collection of male solo yiff posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Yiff -> Female-Solo (8)
	await e.postSets.create({
		name: "[API] Official Yiff -> Female-Solo",
		shortname: "official_yiff_female_solo",
		description: "The official collection of female solo yiff posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Fursuit Butts (9)
	await e.postSets.create({
		name: "[API] Official Fursuit Butts",
		shortname: "official_fursuitbutts",
		description: "The official collection of fursuit butt posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Boop (10)
	await e.postSets.create({
		name: "[API] Official Boop",
		shortname: "official_boop",
		description: "The official collection of boop posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Cuddle (11)
	await e.postSets.create({
		name: "[API] Official Cuddle",
		shortname: "official_cuddle",
		description: "The official collection of cuddle posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Flop (12)
	await e.postSets.create({
		name: "[API] Official Flop",
		shortname: "official_flop",
		description: "The official collection of flop posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Fursuit (13)
	await e.postSets.create({
		name: "[API] Official Fursuit",
		shortname: "official_fursuit",
		description: "The official collection of fursuit posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Hold (14)
	await e.postSets.create({
		name: "[API] Official Hold",
		shortname: "official_hold",
		description: "The official collection of hold posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Howl (15)
	await e.postSets.create({
		name: "[API] Official Howl",
		shortname: "official_howl",
		description: "The official collection of howl posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Hug (16)
	await e.postSets.create({
		name: "[API] Official Hug",
		shortname: "official_hug",
		description: "The official collection of hug posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Kiss (17)
	await e.postSets.create({
		name: "[API] Official Kiss",
		shortname: "official_kiss",
		description: "The official collection of kiss posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Lick (18)
	await e.postSets.create({
		name: "[API] Official Lick",
		shortname: "official_lick",
		description: "The official collection of lick posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
	
	// Propose (19)
	await e.postSets.create({
		name: "[API] Official Propose",
		shortname: "official_propose",
		description: "The official collection of propose posts for \"YiffyAPI V3\":/help/official_sets.",
		public: true
	}).then(set => console.log("Post Set #%d Created - %s (%s)", set.id, set.name, set.shortname));
})
