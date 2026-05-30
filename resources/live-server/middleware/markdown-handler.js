/**
 * Find files to match URL requests and handle any markdown content
 */

const fs = require("fs");
const path = require("node:path");

// Work out where our system directory is
const systemDir = __dirname.replace("/middleware", "");

// Also work out which directory we are running from
const cwd = process.cwd();

// Also need a plugins directory
const pluginsDir = __dirname.replace("/middleware", "/plugins");

// And icons
const iconsDir = __dirname.replace("/middleware", "/icons");

// List of file extensions to pass through unchanged
const passThrough = [
    "gif",
    "htm",
    "html",
    "jpg",
    "pdf",
    "png",
    "svg"
];

// MIME types
const mime = {
    css: "text/css",
    js: "text/javascript",
    mjs: "text/javascript",
    svg: "image/svg+xml"
};

// Read in our HTML template
const html = fs.readFileSync(systemDir + path.sep + "content" + path.sep + "webserver.html").toString().split("<!-- CONTENT -->");

// Work out which icon to use for a file
const getIcon = file => {

    // Somewhere to keep the icon name
    let icon = "blank";

    // We may want to know the file extension
    const extn = path.parse(file.name).ext.replace(/^\./, "");

    // Directories
    if (file.isDirectory()) { icon = "folder"; }

    // Simple extensions
    else if (extn) { icon = extn; }

    // Try and work them out
    else if (/ignore$/.test(file.name)) { icon = "gitignore"; }
    else if (/^\.docker/.test(file.name)) { icon = "docker"; }

    // Check the icon exists
    icon = icon + ".svg";
    if (!fs.existsSync(iconsDir + path.sep + icon)) {
        icon = "blank.svg";
    }

    // Give up trying to work it out
    return icon;
};

// Get a directory listing ready for formatting as markdown
const getFilesInDirectory = (dirpath) => {

    const doubleSlash = RegExp("\\" + path.sep + "\\" + path.sep);

    return fs.readdirSync(dirpath, { withFileTypes: true })
                .reduce((result, file) => {

                    const label = file.name;
                    const link = (file.parentPath + path.sep + file.name)
                                    .replace(doubleSlash, path.sep)
                                    .replace(cwd, "");
                    const icon = getIcon(file);
                    const iconTag = "![" + icon + " icon](/icons/" + icon + ")";

                    return result + "\n\n---\n\n" + iconTag + "[" + label + "](" + link + ")";
                }, "");
};

// Get the content of a file
const getFileContent = (res, filepath, options) => {

    if (fs.existsSync(filepath)) {

        // Handle directories
        if (fs.lstatSync(filepath).isDirectory()) {

            const title = filepath.replace(cwd, "");
            return "---\n" +
                   "css: /plugins/directory.css\n" +
                   "---\n" +
                   "# " + title + "\n" +
                   getFilesInDirectory(filepath) + "\n\n---\n\n";
        }

        // Check for a binary file
        if (options && options.binary) {

            return fs.readFileSync(filepath, { flag: "r" });
        }

        // Assume we have text file format
        return fs.readFileSync(filepath, { encoding: "utf8", flag: "r" });
    }

    return null;
};

// Write the content of a file to the response
const writeFileContent = (res, filepath, options) => {

    const fileContent = getFileContent(res, filepath, options);
    if (fileContent) {
        res.statusCode = 200;
        res.write(fileContent);
        res.end();
    } else {
        console.error("ERROR File not found: " + filepath);
        res.statusCode = 404;
        res.statusMessage = "Not found";
        res.end();
    }
};

// Actual middleware function
module.exports = function(url, res, next) {

    // Get the file extension
    const parsedUrl = path.parse(url);
    const extension = parsedUrl.ext.replace(/^\./, "");

    // Check whether this is a system file
    if (/^\/system\//.test(url)) {

        let filepath = url;
        filepath = filepath.replace(/^\/system\/lib\//, "/lib/");
        filepath = filepath.replace(/^\/system\//, "/content/");
        filepath = systemDir + path.sep + filepath;
        res.setHeader("Content-Type", mime[extension] || "text/plain");
        writeFileContent(res, filepath);
        return;
    }

    // Check for plugins
    if (/^\/plugins\/.+/.test(url)) {
        let filepath = url;
        filepath = filepath.replace(/^\/plugins\//, "");
        filepath = pluginsDir + path.sep + filepath;
        res.setHeader("Content-Type", mime[extension] || "text/plain");
        writeFileContent(res, filepath);
        return;
    }

    // Check for icons
    if (/^\/icons\/.+/.test(url)) {
        let filepath = url;
        filepath = filepath.replace(/^\/icons\//, "");
        filepath = iconsDir + path.sep + filepath;
        res.setHeader("Content-Type", mime[extension] || "text/plain");
        writeFileContent(res, filepath);
        return;
    }

    // Check for favicon
    if (url === "/favicon.ico") {
        const filepath = systemDir + path.sep + "content" + path.sep + "favicon.ico";
        writeFileContent(res, filepath, { binary: true });
        return;
    }

    // Check whether we just pass this through as is
    const filepath = cwd + (path.sep === "/" ? url : url.replace(/\//g, path.sep));
    if (passThrough.includes(extension)) {

        next();
        return
    }

    // From here on down, we are treating as markdown
    // Work out the name of this page and get the content
    const filename = parsedUrl.base;
    const fileContent = getFileContent(res, filepath);
    if (fileContent == null) {
        return;
    }
    let escapedContent = fileContent.replace(/&/g, "&amp;")
                                    .replace(/</g, "&lt;")
                                    .replace(/>/g, "&gt;");

    // If we don't have a final newline, add one
    if (escapedContent.substr(-1) !== "\n") {
        escapedContent = escapedContent + "\n";
    }

    // Render as HTML and embed the file contents
    const dirname = parsedUrl.dir + ( parsedUrl.dir === "/" ? "" : "/");
    res.write(html[0].replace(/<!-- TITLE -->/g, dirname + filename));

    // If it's markdown, we render it
    if (extension === "md" || /^# [^# ]/.test(escapedContent) || /^---/.test(escapedContent)) {
        res.write(escapedContent);

    // Mermaid diagram we use mermaid formatting
    } else if (extension === "mmd") {

        res.write("```mermaid\n");
        res.write(escapedContent);
        res.write("```\n");

    // Anything else we display as text
    } else {

        res.write("```\n");
        res.write(escapedContent);
        res.write("```\n");
    }

    // Remainder of the HTML we need
    res.write(html[1]);
    res.end();
}
