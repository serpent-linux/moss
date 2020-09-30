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

module moss.build.context;

import moss.format.source.spec;
import moss.format.source.script;

/**
 * The BuildContext holds global configurations and variables needed to complete
 * all builds.
 */
struct BuildContext
{
    /** Root of all build operations */
    string rootDir;
    Spec* spec;

    /**
     * Construct a new BuildContect
     */
    this(Spec* spec, string rootDir)
    {
        this.spec = spec;
        this.rootDir = rootDir;

        sbuilder.addDefinition("name", spec.source.name);
        sbuilder.addDefinition("version", spec.source.versionIdentifier);
        sbuilder.addDefinition("release", spec.source.versionIdentifier);

        // TODO: Take from file.
        sbuilder.addDefinition("libsuffix", "");
        sbuilder.addDefinition("prefix", "/usr");
        sbuilder.addDefinition("bindir", "%(prefix)/bin");
        sbuilder.addDefinition("sbindir", "%(prefix)/sbin");
        sbuilder.addDefinition("includedir", "%(prefix)/include");
        sbuilder.addDefinition("datadir", "%(prefix)/share");
        sbuilder.addDefinition("localedir", "%(datadir)/locale");
        sbuilder.addDefinition("infodir", "%(datadir)/info");
        sbuilder.addDefinition("mandir", "%(datadir)/man");
        sbuilder.addDefinition("docdir", "%(datadir)/doc");
        sbuilder.addDefinition("localstatedir", "/var");
        sbuilder.addDefinition("runstatedir", "/run");
        sbuilder.addDefinition("sysconfdir", "/etc");
        sbuilder.addDefinition("osconfdir", "%(datadir)/defaults");
        sbuilder.addDefinition("libdir", "%(prefix)/lib%(libsuffix)");
        sbuilder.addDefinition("libexecdir", "%(libdir)/%(name)");

        sbuilder.addAction("configure", "");
        sbuilder.addAction("make", "");
        sbuilder.addAction("make_install", "");
    }

    /**
     * Return reference to underlying ScriptBuilder so that it may be
     * cloned.
     */
    pure final @property ref auto script() @safe @nogc nothrow
    {
        return sbuilder;
    }

private:

    ScriptBuilder sbuilder;
}
