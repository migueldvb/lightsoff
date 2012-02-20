public class LightsOff : Gtk.Application
{
    private Settings settings;
    private Gtk.Window window;
    private GameView game_view;

    private const GLib.ActionEntry[] action_entries =
    {
        { "new-game",      new_game_cb },
        { "quit",          quit_cb     },
        { "help",          help_cb     },
        { "about",         about_cb    }
    };
    
    private LightsOff ()
    {
        Object (application_id: "org.gnome.lightsoff", flags: ApplicationFlags.FLAGS_NONE);
    }

    protected override void startup ()
    {
        base.startup ();

        add_action_entries (action_entries, this);

        settings = new Settings ("org.gnome.lightsoff");

        window = new Gtk.ApplicationWindow (this);

        var clutter_embed = new GtkClutter.Embed ();
        clutter_embed.show ();
        window.add (clutter_embed);

        var stage = (Clutter.Stage) clutter_embed.get_stage ();
        stage.key_release_event.connect (key_release_event_cb);
        stage.color = Clutter.Color.from_string ("#000000");
        stage.use_fog = false;

        game_view = new GameView (settings.get_int ("level"));
        game_view.level_changed.connect (level_changed_cb);
        game_view.show ();
        stage.add_actor (game_view);

        stage.set_size (game_view.width, game_view.height);
        clutter_embed.set_size_request ((int) stage.width, (int) stage.height);
    }
    
    private void level_changed_cb (int level)
    {
        settings.set_int ("level", level);
    }

    private bool key_release_event_cb (Clutter.Actor actor, Clutter.KeyEvent event)
    {
        switch (event.keyval)
        {
        case Clutter.KEY_Escape:
            game_view.hide_cursor ();
            return true;
        case Clutter.KEY_Down:
            game_view.move_cursor (0, 1);
            return true;
        case Clutter.KEY_Up:
            game_view.move_cursor (0, -1);
            return true;
        case Clutter.KEY_Left:
            game_view.move_cursor (-1, 0);
            return true;
        case Clutter.KEY_Right:
            game_view.move_cursor (1, 0);
            return true;
        case Clutter.KEY_Return:
            game_view.activate_cursor ();
            return true;
        default:
            return false;
        }
    }

    public override void activate ()
    {
        window.present ();
    }

    private void new_game_cb ()
    {
        game_view.reset_game();
    }

    private void quit_cb ()
    {
        window.destroy ();
    }

    private void help_cb ()
    {
        try
        {
            Gtk.show_uri (window.get_screen (), "help:lightsoff", Gtk.get_current_event_time ());
        }
        catch (Error e)
        {
            warning ("Failed to show help: %s", e.message);
        }
    }

    private void about_cb ()
    {
        string[] authors =
        {
            "Tim Horton",
            "Robert Ancell",
            null
        };

        string[] artists =
        {
            "Tim Horton",
            "Ulisse Perusin",
            null
        };

        string[] documenters =
        {
            "Eric Baudais",
            null
        };

        Gtk.show_about_dialog (window,
                               "program-name", _("Lights Off"),
                               "version", Config.VERSION,
                               "comments",
                               _("Turn off all the lights\n\nLights Off is a part of GNOME Games."),
                               "copyright", "Copyright © 2009 Tim Horton",
                               "license", GnomeGamesSupport.get_license (_("Lights Off")),
                               "wrap-license", true,
                               "authors", authors,
                               "artists", artists,
                               "documenters", documenters,
                               "translator-credits", _("translator-credits"),
                               "logo-icon-name", "lightsoff",
                               "website", "http://www.gnome.org/projects/gnome-games",
                               "website-label", _("GNOME Games web site"),
                               null);
    }

    public static int main (string[] args)
    {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Config.GETTEXT_PACKAGE);

        Environment.set_prgname ("lightsoff");

        if (GtkClutter.init (ref args) != Clutter.InitError.SUCCESS)
        {
            warning ("Failed to initialise Clutter");
            return Posix.EXIT_FAILURE;
        }

        GnomeGamesSupport.stock_init ();

        var app = new LightsOff ();
        return app.run ();
    }
}
