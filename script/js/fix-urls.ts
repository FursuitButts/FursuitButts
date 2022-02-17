import E621 from "e621";
import { SYSTEM_TOKEN } from "./secrets";
import { enable } from "debug";
const e = new E621.YiffyAPI({
	authUser: "System",
	authKey: SYSTEM_TOKEN
});

enable("e621:*");
process.nextTick(async() => {
	const posts = await e.posts.search();
	for(const post of posts) {
		const add: Array<string> = [], remove: Array<string> = [];
		post.sources.forEach(source => {
			const ogSource = source;
			if(["furaffinity.net", "patreon.com"].some(s => source.includes(s))) source = source.replace(/http?s:\/\/www\./, "https://");
			if(ogSource !== source) {
				add.push(source);
				remove.push(ogSource);
			}
		});

		if(add.length || remove.length) await post.modify({
			addSources: add,
			removeSources: remove,
			editReason: "Automated Edit - URL Fix"
		});
	}
});
