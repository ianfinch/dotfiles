/* Set up our markdown converter */
var converter = new showdown.Converter();
converter.setOption("literalMidWordUnderscores", true);
converter.setOption("tables", true);
converter.setOption("tasklists", true);
converter.setOption("metadata", true);
converter.setOption("disableForced4SpacesIndentedSublists", true);

// Work out where our plugins directory is (note that document.currentScript
// needs to be called when the code is initially being processed
const pluginDir = document.currentScript.src.split("/").slice(0, -2).join("/") + "/plugins";
console.log(pluginDir);

/* Function to toggle expanded status on click */
const addExpandToggle = (elem, targetClassList) => {

    elem.addEventListener("click", () => {
        if (targetClassList.contains("expanded")) {
            targetClassList.remove("expanded");
        } else {
            targetClassList.add("expanded");
        }
    });
};

/* Utility function to create an element */
const createElement = name => {

    const result = {
        value: document.createElement(name),
        addAttribute: (k, v) => { result.value.setAttribute(k, v); return result; }
    };

    return result;
};

/* Function to add a stylesheet to the page */
const addStyleSheet = cssFile => {

    const link = createElement("link")
                    .addAttribute("href", cssFile)
                    .addAttribute("rel", "stylesheet")
                    .addAttribute("type", "text/css")
                    .value;
    const head = document.getElementsByTagName("head")[0];
    head.appendChild(link);
};

/* Function to handle frontmatter */
const handleFrontmatter = frontmatter => {

    if (frontmatter.css) {
        frontmatter.css.split(/, */).forEach(cssFile => {
            addStyleSheet(pluginDir + "/" + cssFile);
        });
    }
};

/* Function to do the conversion */
const convertMarkdown = async () => {

    // Convert any markdown blocks to HTML
    [...document.getElementsByClassName("markdown")].forEach(elem => {

        const text = elem.textContent.replace(/(```[a-z]+) +/g, "$1");
        const html = converter.makeHtml(text);
        elem.insertAdjacentHTML("afterend", "<article>" + html + "</article>");
        elem.style.display = "none";

        handleFrontmatter(converter.getMetadata());
    });

    // Update the title with the first h1 on the page
    const headers = document.getElementsByTagName("h1");
    if (headers.length > 0) {

        const headerText = headers[0].textContent;
        const title = document.getElementsByTagName("title");
        if (title.length > 0) {

            title[0].textContent = headerText;
        }
    }

    // Add image expansion where needed
    [...document.querySelectorAll("p > img:only-child")].forEach(elem => {
        addExpandToggle(elem, elem.classList);
    });

    // If we have tables, use gridjs to lay them out
    if (gridjs && gridjs.Grid) {

        [...document.getElementsByTagName("table")].forEach(elem => {

            // Add somewhere for the grid to be displayed
            const targetElem = document.createElement("div");
            elem.after(targetElem);

            // Render the grid
            const grid = new gridjs.Grid({
                from: elem,
                sort: true,
                resizable: true
            }).render(targetElem);
        });
    }

    // If we have mermaid diagrams, render them
    mermaid.initialize({ startOnLoad: false });
    await mermaid.run({
        querySelector: ".mermaid",
        postRenderCallback: (id) => {
            const diagram = document.getElementById(id);
            const classes = diagram.parentElement.parentElement.classList;
            diagram.style.width = diagram.style["max-width"];
            diagram.style["max-width"] = "100%";
            addExpandToggle(diagram, classes);
        }
    });

    // Publish an event to allow post-conversion activities
    window.dispatchEvent(new Event("markdownConverted"));
};

// Trigger the conversion after the page has completed loading
addEventListener("load", () => {

    convertMarkdown();
});
