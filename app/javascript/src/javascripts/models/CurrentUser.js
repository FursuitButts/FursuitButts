import Utility from "../utility";

export default class CurrentUser {
  static get id () {
    return Number(document.body.dataset.userId);
  }

  static get name () {
    return document.body.dataset.userName;
  }

  static get level () {
    return Number(document.body.dataset.userLevel);
  }

  static get levelString () {
    return document.body.dataset.userLevelString.toLowerCase().replaceAll(" ", "-");
  }

  static get perPage () {
    return Number(document.body.dataset.userPerPage);
  }

  static get canApprovePosts () {
    return document.body.dataset.userCanApprovePosts === "true";
  }

  static get isBanned () {
    return document.body.dataset.userIsBanned === "true";
  }

  static get isRejected () {
    return document.body.dataset.userIsRejected === "true";
  }

  static get isRestricted () {
    return document.body.dataset.userIsRestricted === "true";
  }

  static get isMember () {
    return document.body.dataset.userIsMember === "true";
  }

  static get isTrusted () {
    return document.body.dataset.userIsTrusted === "true";
  }

  static get isFormerStaff () {
    return document.body.dataset.userIsFormerStaff === "true";
  }

  static get isJanitor () {
    return document.body.dataset.userIsJanitor === "true";
  }

  static get isModerator () {
    return document.body.dataset.userIsModerator === "true";
  }

  static get isSystem () {
    return document.body.dataset.userIsSystem === "true";
  }

  static get isAdmin () {
    return document.body.dataset.userIsAdmin === "true";
  }

  static get isOwner () {
    return document.body.dataset.userIsOwner === "true";
  }

  static get isLocked () {
    return document.body.dataset.userIsLocked === "true";
  }

  static get isApprover () {
    return document.body.dataset.userIsApprover === "true";
  }

  static get unrestrictedUploads () {
    return document.body.dataset.userUnrestrictedUploads === "true";
  }

  static get commentThreshold () {
    return Number(Utility.meta("user-comment-threshold"));
  }

  static get blacklistedTags () {
    return JSON.parse(Utility.meta("blacklisted-tags"));
  }

  static get userBlocks () {
    return JSON.parse(Utility.meta("user-blocks"));
  }

  static get enableJsNavigation () {
    return Utility.meta("enable-js-navigation") === "true";
  }

  static get enableAutocomplete () {
    return Utility.meta("enable-autocomplete") === "true";
  }

  static get styleUsernames () {
    return Utility.meta("style-usernames") === "true";
  }
}
