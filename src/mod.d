module mod;

import std.conv;

import dscord.core,
       jeff.main,
       jeff.perms;

class ModPlugin : Plugin, UserGroupGetter {
  VibeJSON perms;
  int[string] groups;

  this() {
    auto opts = new PluginOptions;
    opts.useStorage = true;
    opts.useConfig = true;
    super(opts);
  }

  override void load(Bot bot, PluginState state = null) {
    super.load(bot, state);
    this.perms = this.storage.ensureObject("perms");

    if (this.config.has("groups")) {
      foreach (string k, VibeJSON v; this.config["groups"]) {
        this.groups[k] = v.get!int;
      }
    }
  }

  int getGroup(User u) {
    if (!(u.id.to!string in this.perms)) {
      return 0;
    }

    return this.perms[u.id.to!string].get!int;
  }

  @Command("set")
  @CommandGroup("group")
  @CommandDescription("set a users group")
  @CommandLevel(Level.ADMIN)
  void setUserGroup(CommandEvent e) {
    if (e.msg.mentions.length != 2) {
      e.msg.reply("Must supply one user and one group");
      return;
    }

    // Check if the group exists
    if (e.args[0] !in this.groups) {
      e.msg.replyf("Invalid group: `%s`", e.args[0]);
      return;
    }

    auto user = e.msg.mentions.values[1];
    this.perms[user.id.to!string] = VibeJSON(this.groups[e.args[0]]);
    e.msg.replyf("Ok, added %s to group %s", user.username, e.args[0]);
  }

  @Command("get")
  @CommandGroup("group")
  @CommandDescription("get a users group")
  @CommandLevel(Level.MOD)
  void getUserGroup(CommandEvent e) {
    if (e.msg.mentions.length != 2) {
      e.msg.reply("Must supply one user to lookup!");
      return;
    }

    auto user = e.msg.mentions.values[1];

    if (!(user.id.to!string in this.perms)) {
      e.msg.replyf("No group set for user %s", user.username);
      return;
    }

    auto userLevel = this.perms[user.id.to!string].get!int;
    foreach (name, level; this.groups) {
      if (level == userLevel) {
        e.msg.replyf("User %s is in group %s", user.username, level);
        return;
      }
    }

    e.msg.replyf("User %s has level %s", user.username, userLevel);
  }

  @Command("list")
  @CommandGroup("group")
  @CommandDescription("list all groups")
  @CommandLevel(Level.MOD)
  void getGroups(CommandEvent e) {
    if (!this.groups.length) {
      e.msg.replyf("No groups currently set.");
      return;
    }

    MessageTable table = new MessageTable;

    // Header
    table.setHeader("Name", "Level");

    foreach (name, level; this.groups) {
      table.add(name, level.toString);
    }

    // Sort by level
    table.sort(1, (arg) => arg.to!int);
    e.msg.reply(table);
  }

  @Command("kick")
  @CommandDescription("kick a user")
  @CommandLevel(Level.MOD)
  void kickUser(CommandEvent e) {
    if (e.msg.mentions.length != 2) {
      e.msg.reply("Must supply user to kick!");
      return;
    }

    auto user = e.msg.mentions.values[1];
    e.msg.guild.kick(user);
    e.msg.replyf("Kicked user %s", user.username);
  }
}

extern (C) Plugin create() {
  return new ModPlugin;
}
