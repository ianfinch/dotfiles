/**
 * Generate a static version of the site
 */

const markdown = require("./markdown-handler");
const fs = require("fs");
const path = require("path");

// Check the user has passed in a source and target directory
if (process.argv.length !== 4) {

    console.error("Syntax: " + path.basename(process.argv[1]) + " <source directory> <target directory>");
    process.exit(1);
}

// Quick reference for the directories
const sourceRoot = process.argv[2];
const targetRoot = process.argv[3];

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
const processOutputFile = (content, targetFile, depth) => {

    // Make it an html filename
    if (/\.md$/.test(targetFile)) {

        targetFile = targetFile.replace(/\.md$/, "_md.html");
    }

    // Fix references to system files
    if (/\.html$/.test(targetFile)) {

        content = content.replace(/(src|href)="\/system\//g, "$1=\"./system/");
    }

    // Write the file
    fs.writeFileSync(targetFile, content);
};

// Functions to write the result from the markdown middleware
const resultWriter = (targetFile, depth) => {

    // Somewhere to store our result
    let result = "";

    return {
        statusCode: 200,
        statusMessage: "Success",
        setHeader: () => {},
        write: content => { result = result + content; },
        end: () => {

            processOutputFile(result, targetFile, depth);
            result = "";
        }
    };
};

// Function to just copy a file across
const fileCopier = (sourceFile, targetFile) => {

    return () => {

        console.log(sourceFile + " -> " + targetFile);
    };
};

// Copy a directory across
const generateDirectory = (source, target, depth = 0) => {

    const files = fs.readdirSync(source, { withFileTypes: true });
    files.forEach(file => {

        const sourceFile = file.parentPath + path.sep + file.name;
        const targetFile = target + path.sep + file.name;
        if (fs.lstatSync(sourceFile).isDirectory()) {

            console.log(sourceFile + "/ -> " + targetFile + "/_index.md");
            generateDirectory(sourceFile, targetFile, depth + 1);
        } else {

            markdown(sourceFile, "./", resultWriter(targetFile, depth), fileCopier(sourceFile, targetFile));
        }
    });
};

// Create any system files
const createSystemFiles = (targetDir) => {

    const root = path.dirname(path.dirname(process.argv[1]));

    // Create any directories we need
    [ "/system", "/system/content", "/system/lib", "/system/plugins", "/system/icons" ].forEach(dir => {

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
};

generateDirectory(sourceRoot, targetRoot);
createSystemFiles(targetRoot);
