/*
 * This file is part of moss.
 *
 * Copyright © 2020 Serpent OS Developers
 *
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

module moss.cli.processor;

import moss.cli : Command, ExitStatus;
import moss.cli.helpCommand;
import moss.cli.versionCommand;
import moss.cli.installCommand;
import moss.cli.removeCommand;
import moss.cli.searchCommand;
import moss.cli.buildCommand;

import std.stdio;
import std.getopt;
import std.algorithm.mutation : remove;

/**
 * The cli.Processor provides a simple subcommand oriented processing system
 * with which to dispatch and handle CLI arguments.
 */

final struct Processor
{

private:

    string[] _argv;
    const string _name; /* CLI Name */
    Option[] _options; /* Getopt options */
    string _rootDirectory = "/";

    /**
     * Builtin list of handlers
     */
    static const Command*[] handlers = [
        &installCommand, &removeCommand, &searchCommand, &buildCommand,
        &helpCommand, &versionCommand
    ];

public:

    @disable this();

    /**
     * Construct a new Processor
     */
    this(string[] argv) @safe @nogc nothrow
    {
        this._name = argv[0];
        this._argv = argv;
    }

    /**
     * Process all arguments and dispatch to the right caller
     */
    final ExitStatus process()
    {
        bool debugFlag = false;
        bool versionFlag = false;
        bool helpFlag = false;

        /* Ignore unknowns and let the individual commands handle it */
        auto result = getopt(_argv, std.getopt.config.passThrough, std.getopt.config.bundling,
                std.getopt.config.caseSensitive, "version", "Show the program version and exit",
                &versionFlag, "D|destdir", "Set the system root", &_rootDirectory);
        _options = result.options;
        _options[2].help = "Show help information";

        popArg(0);

        if (versionFlag)
        {
            return findHandler("version").exec(this);
        }

        if (argv.length < 1)
        {
            if (result.helpWanted)
            {
                return findHandler("help").exec(this);
            }
            printUsage();
            return ExitStatus.Failure;
        }

        /* Print help on the command */
        const auto command = _argv[0];
        if (result.helpWanted)
        {
            _argv = [command];
            return findHandler("help").exec(this);
        }

        /* Execute the command itself */
        auto handler = findHandler(argv[0]);
        if (handler is null)
        {
            stderr.writefln("Unknown command: %s", command);
            printUsage();
            return ExitStatus.Failure;
        }

        /* Pop command. */
        popArg(0);

        /* Only for development. */
        assert(handler.exec !is null, "Unimplemented execution handler");

        return handler.exec(this);
    }

    /**
     * Return the command that matches the input name
     */
    const(Command*) findHandler(string name) @safe @nogc nothrow
    {
        import std.algorithm;

        auto find = handlers.find!((a, b) => (a.matches(b)))(name);
        return find.length > 0 ? find[0] : null;
    }

    /**
     * Obtain reference to arguments
     */
    pure @property ref const(string[]) argv() @safe @nogc nothrow
    {
        return cast(const(string[])) _argv;
    }

    /**
     * Return the name of the process (argv[0])
     */
    pure @property const(string) name() @safe @nogc nothrow
    {
        return _name;
    }

    /**
     * Return the root directory for all operations
     */
    pure @property const(string) rootDirectory() @safe @nogc nothrow
    {
        return _rootDirectory;
    }

    /**
     * Pop argument at the given position
     */
    void popArg(int index) @safe @nogc nothrow
    {
        this._argv = this._argv.remove(index);
    }

    void printUsage()
    {
        writefln("%s: [command] [--options]\n", name);
        defaultGetoptPrinter("Options: ", _options);
    }

    /**
     * Print the usage, and all supported subcommands
     */
    void printGlobalHelp()
    {
        import std.algorithm;
        import std.range;
        import std.stdio;
        import std.string : format;

        /* Automatically pad */
        auto largestName = handlers.maxElement!("a.primary").primary.length;
        auto largestAlias = handlers.maxElement!("a.secondary").secondary.length;
        auto maxPad = largestName + largestAlias;
        maxPad *= 2;

        foreach (const ref h; handlers)
        {
            string cmdString;
            if (h.secondary !is null)
            {
                cmdString = "%s (%s)".format(h.primary, h.secondary);
            }
            else
            {
                cmdString = "%s".format(h.primary);
            }
            writefln("%*s - %s", maxPad, cmdString, h.blurb);
        }
    }
}
