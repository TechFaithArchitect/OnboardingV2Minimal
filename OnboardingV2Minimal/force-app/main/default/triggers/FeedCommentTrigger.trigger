trigger FeedCommentTrigger on FeedComment(after insert) {
    new FeedCommentTriggerHandler().run();
}