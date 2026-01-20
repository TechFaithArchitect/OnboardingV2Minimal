trigger NetworkMemberTrigger on NetworkMember(before insert, after insert, before update, after update, after delete) {
    new NetworkMemberTriggerHandler().run();
}