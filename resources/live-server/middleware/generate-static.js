/**
 * Generate a static version of the site
 */

const markdown = require("./markdown-handler");
const fs = require("fs");
const path = require("path");

// Check the user has passed in a source and target directory
if (process.argv.length !== 4 && process.argv.length !== 5) {

    console.error("Syntax: " + path.basename(process.argv[1]) + " <source directory> <target directory> [<plugin directory>]");
    process.exit(1);
}

// Want to know where we are working from
const pwd = process.cwd();

// Quick reference for the directories
const sourceRoot = process.argv[2];
const targetRoot = process.argv[3];
const pluginDir = process.argv[4] || sourceRoot + "/plugins";

// Check we have directories
if (!fs.existsSync(sourceRoot)) {

    console.error("Error: " + sourceRoot + " directory does not exist");
    process.exit(1);
}
if (!fs.existsSync(targetRoot)) {

    console.error("Error: " + targetRoot + " directory does not exist");
    process.exit(1);
}

// Process an output file
const processOutputFile = (content, sourceUrl, targetFile, depth) => {

    // Give markdown files html filenames
    if (/\.md$/.test(targetFile)) {

        // Update the filename
        targetFile = targetFile.replace(/\.md$/, "_md.html");

        // If it's a directory listing, we need to tweak it slightly
        if (/\/_index_md\.html$/.test(targetFile)) {

            // Modify the links because they use a full path
            const linkRegex = RegExp("]\\(" + sourceUrl, "g");
            content = content.replace(linkRegex, "](.");

            // Also remove the source root from the directory title
            const h1Regex = RegExp("# /" + sourceRoot);
            content = content.replace(h1Regex, "#");
        }

        // Remove the source root from the header
        const headerRegex = RegExp("<header>/" + sourceRoot);
        content = content.replace(headerRegex, "<header>");
    }

    // Fix references to other files
    if (/\.html$/.test(targetFile)) {

        let prefix = ".";
        if (depth > 0) {

            prefix = Array(depth).fill("..").join("/");
        }

        // Fix up system links in HTML tags
        content = content.replace(/(src|href)="\/system\//g, "$1=\"" + prefix + "/system/");

        // We may also have system icons in our markdown
        content = content.replace(/]\(\/system\/icons\//g, "](" + prefix + "/system/icons/");

        // We also need to take care of system and plugin links in our front matter
        content = content.replace(/css:  *\/system\/plugins\//g, "css: " + prefix + "/system/plugins/");
        content = content.replace(/css:  *\/plugins\//g, "css: " + prefix + "/plugins/");

        // Update any links to *.md to be *_md.html
        content = content.replace(/\.md\)/g, "_md.html)");

        // Assume that a link ending with a slash is a directory, so add a
        // link to the directory listing file
        content = content.replace(/\/\)/g, "/_index_md.html)");
    }

    // Write the file
    fs.writeFileSync(targetFile, content);
};

// Functions to write the result from the markdown middleware
const resultWriter = (sourceUrl, targetFile, depth) => {

    // Somewhere to store our result
    let result = "";

    return {
        statusCode: 200,
        statusMessage: "Success",
        setHeader: () => {},
        write: content => { result = result + content; },
        end: () => {

            processOutputFile(result, sourceUrl, targetFile, depth);
            result = "";
        }
    };
};

// Function to just copy a file across
const fileCopier = (sourceFile, targetFile) => {

    return () => {

        fs.copyFileSync(sourceFile, targetFile);
    };
};

// Copy a directory across
const generateDirectory = (source, target, depth = 0) => {

    const files = fs.readdirSync(source, { withFileTypes: true });
    files.forEach(file => {

        const sourceFile = file.parentPath + path.sep + file.name;
        const sourceUrl = "/" + sourceFile;
        const targetFile = target + path.sep + file.name;
        if (fs.lstatSync(sourceFile).isDirectory()) {

            // If we don't have the target directory, create it
            if (!fs.existsSync(targetFile)) {

                fs.mkdirSync(targetFile);
            }

            // Generate an index file for the directory
            markdown(sourceUrl, pwd, resultWriter(sourceUrl, targetFile + "/_index.md", depth + 1), () => null);

            // Copy over the directory contents
            generateDirectory(sourceFile, targetFile, depth + 1);
        } else {

            markdown(sourceUrl, pwd, resultWriter(sourceUrl, targetFile, depth), fileCopier(sourceFile, targetFile));
        }
    });
};

// Create any system files
const createSystemFiles = (targetDir, pluginDir) => {

    const root = path.dirname(path.dirname(process.argv[1]));

    // Create any directories we need
    [ "/system", "/system/content", "/system/lib", "/system/plugins", "/system/icons", "/plugins" ].forEach(dir => {

        if (!fs.existsSync(targetDir + dir)) {
            fs.mkdirSync(targetDir + dir);
        }
    });

    // Copy across the system files
    const files = [ fs.readdirSync(root + "/content").map(x => ["content/" + x, "system/content/" + x]),
                    fs.readdirSync(root + "/lib").map(x => ["lib/" + x, "system/lib/" + x]),
                    fs.readdirSync(root + "/plugins").map(x => ["plugins/" + x, "system/plugins/" + x]),
                    fs.readdirSync(root + "/icons").map(x => ["icons/" + x, "system/icons/" + x]) ].flat();
    files.forEach(([source, target]) => {

        fs.copyFileSync(root + path.sep + source, targetDir + path.sep + target);
    });

    // Copy the plugins
    const pluginFiles = fs.readdirSync(pluginDir);
    pluginFiles.forEach(plugin => {

        fs.copyFileSync(pluginDir + path.sep + plugin, targetDir + path.sep + "plugins" + path.sep + plugin);
    });
};

generateDirectory(sourceRoot, targetRoot);
createSystemFiles(targetRoot, pluginDir);
