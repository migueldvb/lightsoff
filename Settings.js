Gtk = imports.gi.Gtk;
Gio = imports.gi.Gio;
GtkBuilder = imports.gtkbuilder;
main = imports.main;
GConf = imports.gi.GConf;

GConf.init(Seed.argv);

// Defaults
var theme, score;

try
{
	gconf_client = GConf.Client.get_default();
	score = gconf_client.get_int("/apps/lightsoff/score");
	theme = imports.themes[gconf_client.get_string("/apps/lightsoff/theme")].theme;
}
catch(e)
{
	Seed.print("Couldn't load settings from GConf.");
	theme = imports.themes["tango"].theme;
	score = 1;
}

// Settings Event Handler

SettingsWatcher = new GType({
	parent: Gtk.Button.type, // Can I make something inherit directly from GObject?!
	name: "SettingsWatcher",
	signals: [{name: "theme_changed"}],
	init: function()
	{
		
	}
});

var Watcher = new SettingsWatcher();

// Settings UI

handlers = {
	select_theme: function(selector, ud)
	{
		new_theme = imports.themes[selector.get_active_text()].theme;
		
		if(new_theme == theme)
			return;
		
		theme = new_theme;
		theme.map_stuff(main.stage);
		
		try
		{
			gconf_client.set_string("/apps/lightsoff/theme", selector.get_active_text());
		}
		catch(e)
		{
			Seed.print("Couldn't save settings to GConf.");
		}
	
		Watcher.signal.theme_changed.emit();
	},
	close_settings: function()
	{
		//settings_dialog.hide_all();
	}
};

// Settings UI Helper Functions

function show_settings()
{
	b = new Gtk.Builder();
	b.add_from_file(main.file_prefix+"/settings.ui");
	b.connect_signals(handlers);

	populate_theme_selector(b.get_object("theme-selector"));

	settings_dialog = b.get_object("dialog1");
	settings_dialog.set_transient_for(main.window);
	
	var result = settings_dialog.run();
	
	settings_dialog.destroy();
}

function populate_theme_selector(selector)
{
	// Since we're using GtkBuilder, we can't make a Gtk.ComboBox.text. Instead,
	// we'll construct the cell renderer here, once, and use that.
	var cell = new Gtk.CellRendererText();
	selector.pack_start(cell, true);
	selector.add_attribute(cell, "text", 0);

	file = Gio.file_new_for_path(main.file_prefix+"/themes");
	enumerator = file.enumerate_children("standard::name");
	
	var i = 0;

	while((child = enumerator.next_file()))
	{
		var fname = child.get_name();
		selector.append_text(fname);
		
		if(fname == theme.name)
			selector.set_active(i);
		
		i++;
	}
}