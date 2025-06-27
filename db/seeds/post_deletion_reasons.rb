# frozen_string_literal: true

module PostDeletionReasons
  def self.run!(user = User.system)
    [
      "Inferior version/duplicate of post #%PARENT_ID%",
      "Previously deleted (post #%PARENT_ID%)",
      "Excessive same base image set",
      "Colored base",
      { title: "Advert", prompt: "being an advertisement", reason: "Advertisement" },
      "Underage artist",
      "",
      { title: "Artistic", prompt: "artistic standards", reason: "Does not meet minimum quality standards (Artistic)" },
      "Does not meet minimum quality standards (Resolution)",
      "Does not meet minimum quality standards (Compression)",
      { title: "Bad Edit", prompt: "being a bad edit", reason: "Does not meet minimum quality standards (Trivial or low quality edit)" },
      { title: "Photo/Scan", prompt: "being a photo/scan", reason: "Does not meet minimum quality standards (Bad digitization of traditional media)" },
      "Does not meet minimum quality standards (Photo)",
      "Does not meet minimum quality standards (%OTHER_ID%)",
      "Broken/corrupted file",
      "JPG resaved as PNG",
      "",
      { title: "Human", prompt: "being human only", reason: "Irrelevant to site (Human only)" },
      { title: "Screencap", prompt: "being a screencap", reason: "Irrelevant to site (Screencap)" },
      "Irrelevant to site (Zero pictured)",
      { title: "AI / Gen", prompt: "being AI generated", reason: "Irrelevant to site (AI assisted/generated)" },
      "Irrelevant to site (%OTHER_ID%)",
      "",
      "Paysite/commercial content",
      "Traced artwork",
      "Traced artwork (post #%PARENT_ID%)",
      "Takedown #%OTHER_ID%",
      "The artist of this post is on the \"avoid posting list\":/static/avoid_posting",
      "[[conditional_dnp|Conditional DNP]] (Only the artist is allowed to post)",
      "[[conditional_dnp|Conditional DNP]] (%OTHER_ID%)",
    ].each_with_index.map do |data, index|
      next if data == ""
      unless data.is_a?(Hash)
        data = { reason: data }
      end

      PostDeletionReason.find_or_create_by!(**data, order: index + 1, creator: user.resolvable)
    end
  end
end
