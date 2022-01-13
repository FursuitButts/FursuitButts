let PostDeletion = {};

PostDeletion.init = function() {
  const input = $("#reason");
  let inputVal = String(input.val());

  const buttons = $("a.delreason-button")
    .on("click", (event) => {
      event.stopPropagation();
      event.preventDefault();

      const $button = $(event.target);
      if (!$button.is("a")) {return;}

      const text = $button.data("processed");
      input.val((index, current) => {
        current = current.trim();
        if ($button.hasClass("enabled")) {
          return current
            .replace(text, "")
            .replace(/ \/ $|^ \/ /g, "") // trim leading and trailing slashes
            .replace(/( \/ ){2,}/g, " / "); // trim duplicate / leftover slashes
        } else {return (current ? current + " / " : "") + text;}
      });
      input.trigger("input");
    })
    .on("yapi:refresh", (event) => {
      const $button = $(event.target);
      let text = $button.data("text");
      for (const buttonInput of $button.find("input[type=text]")) {text = text.replace("%ID%", $(buttonInput).val());}

      $button.data("processed", text);
      $button.toggleClass("enabled", inputVal.indexOf(text) >= 0);
    })
    .each((index, element) => {
      const $button = $(element);
      $button.find("input[type=text]").on("input", () => {
        $button.trigger("yapi:refresh");
      })
    });
  buttons.trigger("yapi:refresh");

  input.on("input", () => {
    inputVal = String(input.val());
    buttons.trigger("yapi:refresh");
  });

  $("#delreason-clear").on("click", () => {
    input.val("").trigger("input");
  });
}

$(function() {
  if ($("div#c-confirm-delete").length) {Danbooru.PostDeletion.init();}
});

export default PostDeletion
