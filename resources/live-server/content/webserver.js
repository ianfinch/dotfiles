/* Set up our markdown converter */
var converter = new showdown.Converter();
converter.setOption("literalMidWordUnderscores", true);
converter.setOption("tables", true);
converter.setOption("tasklists", true);
converter.setOption("metadata", true);
converter.setOption("disableForced4SpacesIndentedSublists", true);

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

/* Function to check file is in plugins directory, and include it if it is */
const includePlugin = (file, fn) => {

    if (/^\/plugins\//.test(file)) {
        fn(file);
    } else {
        alert("ERROR: Tried to include non-plugin file: " + file);
    }
}

/* Function to handle frontmatter */
const handleFrontmatter = frontmatter => {

    if (frontmatter.css) {
        frontmatter.css.split(/, */).forEach(cssFile => {
            includePlugin(cssFile, addStyleSheet);
        });
    }
};

/* Convert any markdown blocks to HTML */
[...document.getElementsByClassName("markdown")].forEach(elem => {

    const text = elem.textContent.replace(/(```[a-z]+) +/g, "$1");
    const html = converter.makeHtml(text);
    elem.insertAdjacentHTML("afterend", "<article>" + html + "</article>");
    elem.style.display = "none";

    handleFrontmatter(converter.getMetadata());
});

/* Add image expansion where needed */
[...document.querySelectorAll("p > img:only-child")].forEach(elem => {
    addExpandToggle(elem, elem.classList);
});

/* If we have mermaid diagrams, render them */
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
