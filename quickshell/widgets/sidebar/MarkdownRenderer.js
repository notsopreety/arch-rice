function highlightCode(code, lang) {
    // Escape HTML special characters first
    let escaped = code
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;");

    lang = (lang || "").toLowerCase().trim();

    // JSON syntax highlighting
    if (lang === "json" || lang === "json5") {
        return escaped.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+-]?\d+)?)/g, function (match) {
            var cls = 'color: #f43f5e;'; // number (rose)
            if (/^"/.test(match)) {
                if (/:$/.test(match)) {
                    cls = 'color: #c084fc; font-weight: bold;'; // key (purple)
                } else {
                    cls = 'color: #34d399;'; // string (emerald)
                }
            } else if (/true|false/.test(match)) {
                cls = 'color: #fb923c; font-weight: bold;'; // boolean (orange)
            } else if (/null/.test(match)) {
                cls = 'color: #94a3b8;'; // null (slate)
            }
            return '<span style="' + cls + '">' + match + '</span>';
        });
    }

    // Keyword list for C-style, Python, JS, QML
    const keywords = [
        "break", "case", "catch", "class", "const", "continue", "debugger", "default", "delete", "do", "else", "export",
        "extends", "finally", "for", "function", "if", "import", "in", "instanceof", "new", "return", "super", "switch",
        "this", "throw", "try", "typeof", "var", "void", "while", "with", "yield", "let", "static", "enum", "await",
        "async", "def", "elif", "except", "lambda", "pass", "print", "from", "as", "global", "nonlocal",
        "assert", "del", "True", "False", "None", "and", "or", "not", "is", "pragma", "property", "readonly", "alias"
    ];

    const keywordRegex = new RegExp('\\b(' + keywords.join('|') + ')\\b', 'g');
    let placeholders = [];
    
    // 0. Python triple-quoted docstrings (double and single triple quotes)
    if (lang === "python" || lang === "py") {
        escaped = escaped.replace(/("""[\s\S]*?"""|'''[\s\S]*?''')/g, function(match) {
            let id = "___COM___" + placeholders.length + "___";
            placeholders.push({ id: id, html: '<span style="color: #94a3b8; font-style: italic;">' + match + '</span>' }); // Slate Gray
            return id;
        });
    }

    // 1. Strings (single quotes, double quotes, backticks)
    let text = escaped.replace(/("(\\.|[^"\\])*"|'(\\.|[^'\\])*'|`(\\.|[^`\\])*`)/g, function(match) {
        let id = "___STR___" + placeholders.length + "___";
        placeholders.push({ id: id, html: '<span style="color: #34d399;">' + match + '</span>' }); // Emerald Green
        return id;
    });

    // 2. Comments (/* */ and // and #)
    const isHashCommentLang = ["python", "py", "bash", "sh", "shell", "yaml", "yml", "dockerfile", "makefile", "conf", "ini", "properties"].includes(lang) || 
                              !["c", "cpp", "c++", "csharp", "cs", "java", "javascript", "js", "typescript", "ts", "css", "html", "qml"].includes(lang);
    let commentRegex = isHashCommentLang ? /(\/\*([\s\S]*?)\*\/|(?<!:)\/\/.*|#.*)/g : /(\/\*([\s\S]*?)\*\/|(?<!:)\/\/.*)/g;
    text = text.replace(commentRegex, function(match) {
        let id = "___COM___" + placeholders.length + "___";
        placeholders.push({ id: id, html: '<span style="color: #94a3b8; font-style: italic;">' + match + '</span>' }); // Slate Gray
        return id;
    });

    // 3. Highlight keywords
    text = text.replace(keywordRegex, '<span style="color: #fb7185; font-weight: bold;">$1</span>'); // Rose Red

    // 4. Highlight QML/C++/JS builtins and objects
    const types = ["console", "log", "error", "warn", "document", "window", "root", "parent", "self", "Rectangle", "Item", "Text", "DankIcon", "MouseArea", "Theme", "Row", "Column", "RowLayout", "ColumnLayout", "ListView", "Repeater", "int", "float", "double", "char", "void", "bool", "string", "ListModel", "Qt", "Math", "JSON", "Process", "StdioCollector", "Settings", "FileView", "Timer"];
    const typesRegex = new RegExp('\\b(' + types.join('|') + ')\\b', 'g');
    text = text.replace(typesRegex, '<span style="color: #60a5fa;">$1</span>'); // Sky Blue

    // 5. Highlight function calls
    text = text.replace(/\b([a-zA-Z_][a-zA-Z0-9_]*)(?=\s*\()/g, '<span style="color: #c084fc;">$1</span>'); // Purple

    // 6. Highlight numbers
    text = text.replace(/\b(\d+(?:\.\d+)?)\b/g, '<span style="color: #fb923c;">$1</span>'); // Orange

    // Restore comments and strings
    for (let i = placeholders.length - 1; i >= 0; i--) {
        text = text.split(placeholders[i].id).join(placeholders[i].html);
    }

    return text;
}
function dedent(code) {
    if (!code) return "";
    let lines = code.split("\n");
    // Strip leading empty lines
    while (lines.length > 0 && lines[0].trim() === "") {
        lines.shift();
    }
    // Strip trailing empty lines
    while (lines.length > 0 && lines[lines.length - 1].trim() === "") {
        lines.pop();
    }
    if (lines.length === 0) return "";
    
    // Find common minimum indentation of non-empty lines
    let minIndent = Infinity;
    for (let i = 0; i < lines.length; i++) {
        let line = lines[i];
        if (line.trim() === "") continue;
        let match = line.match(/^(\s*)/);
        let indent = match ? match[1].length : 0;
        if (indent < minIndent) {
            minIndent = indent;
        }
    }
    
    // Strip the common indentation
    if (minIndent > 0 && minIndent !== Infinity) {
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].trim() !== "") {
                lines[i] = lines[i].substring(minIndent);
            } else {
                lines[i] = "";
            }
        }
    }
    return lines.join("\n");
}

function parseBlocks(md) {
    if (!md) return [];

    let tempMd = md.replace(/\r\n/g, "\n");

    // Code block regex matching backticks
    let codeBlockRegex = /```([a-zA-Z0-9_+-]*)\n([\s\S]*?)```/g;
    let blocks = [];
    let lastIndex = 0;
    let match;

    while ((match = codeBlockRegex.exec(tempMd)) !== null) {
        let textPart = tempMd.substring(lastIndex, match.index);
        // Add text block if it contains actual content
        if (textPart.trim() !== "" || textPart.includes("\n\n")) {
            blocks.push({
                type: "text",
                content: parseMarkdownText(textPart)
            });
        }

        blocks.push({
            type: "code",
            lang: match[1] || "code",
            code: dedent(match[2])
        });

        lastIndex = codeBlockRegex.lastIndex;
    }

    let remainingText = tempMd.substring(lastIndex);
    if (remainingText.trim() !== "" || remainingText.includes("\n\n")) {
        blocks.push({
            type: "text",
            content: parseMarkdownText(remainingText)
        });
    }

    return blocks;
}

function parseMarkdownText(escaped) {
    if (!escaped) return "";

    let pLines = escaped.split("\n");
    let result = [];
    let pInList = false;
    let pListType = "";
    let pInTable = false;
    let pTableRows = [];

    for (let i = 0; i < pLines.length; i++) {
        let line = pLines[i];
        let trimmed = line.trim();

        // Headings
        if (trimmed.startsWith("#")) {
            closeListAndTable(result, pInList, pListType, pInTable, pTableRows);
            pInList = false;
            pInTable = false;

            let hLevel = 0;
            while (hLevel < trimmed.length && trimmed.charAt(hLevel) === '#') {
                hLevel++;
            }
            if (hLevel >= 1 && hLevel <= 6 && trimmed.charAt(hLevel) === ' ') {
                let hText = trimmed.substring(hLevel + 1);
                hText = parseInline(hText);
                let hStyles = [
                    'color: #a855f7; font-size: 15px; font-weight: bold; margin-top: 10px; margin-bottom: 4px; border-bottom: 1px solid rgba(255,255,255,0.08); padding-bottom: 2px;',
                    'color: #c084fc; font-size: 13px; font-weight: bold; margin-top: 8px; margin-bottom: 4px; border-bottom: 1px solid rgba(255,255,255,0.06); padding-bottom: 1px;',
                    'color: #cbd5e1; font-size: 12px; font-weight: bold; margin-top: 8px; margin-bottom: 4px;',
                    'color: #ffffff; font-size: 11px; font-weight: bold; margin-top: 6px; margin-bottom: 2px;',
                    'color: #cbd5e1; font-size: 10px; font-weight: bold; margin-top: 6px; margin-bottom: 2px;',
                    'color: #94a3b8; font-size: 9px; font-weight: bold; margin-top: 6px; margin-bottom: 2px;'
                ];
                result.push('<h' + hLevel + ' style="' + hStyles[hLevel - 1] + '">' + hText + '</h' + hLevel + '>');
                continue;
            }
        }

        // Horizontal Rule
        if (trimmed === "---" || trimmed === "___" || trimmed === "***") {
            closeListAndTable(result, pInList, pListType, pInTable, pTableRows);
            pInList = false;
            pInTable = false;
            result.push('<hr style="border: 0; height: 1px; background-color: rgba(255,255,255,0.08); margin-top: 8px; margin-bottom: 8px;" />');
            continue;
        }

        // Blockquotes
        if (trimmed.startsWith("&gt;")) {
            closeListAndTable(result, pInList, pListType, pInTable, pTableRows);
            pInList = false;
            pInTable = false;

            let qText = line.substring(line.indexOf("&gt;") + 4).trim();
            qText = parseInline(qText);
            result.push('<div style="color: #cbd5e1; border-left: 3px solid #c084fc; padding-left: 8px; margin-top: 4px; margin-bottom: 4px; background-color: rgba(255,255,255,0.02); padding-top: 2px; padding-bottom: 2px; border-radius: 0 4px 4px 0;">' + qText + '</div>');
            continue;
        }

        // Unordered Lists
        let ulMatch = line.match(/^(\s*)([*+-])\s+(.*)$/);
        if (ulMatch) {
            let textContent = ulMatch[3];
            textContent = parseInline(textContent);

            if (pInTable) {
                closeTable(result, pTableRows);
                pInTable = false;
            }

            if (!pInList || pListType !== "ul") {
                if (pInList) closeList(result, pListType);
                result.push('<ul style="margin-top: 2px; margin-bottom: 2px; padding-left: 14px; color: #e2e8f0; line-height: 1.2;">');
                pInList = true;
                pListType = "ul";
            }
            result.push('<li>' + textContent + '</li>');
            continue;
        }

        // Ordered Lists
        let olMatch = line.match(/^(\s*)(\d+)\.\s+(.*)$/);
        if (olMatch) {
            let textContent = olMatch[3];
            textContent = parseInline(textContent);

            if (pInTable) {
                closeTable(result, pTableRows);
                pInTable = false;
            }

            if (!pInList || pListType !== "ol") {
                if (pInList) closeList(result, pListType);
                result.push('<ol style="margin-top: 2px; margin-bottom: 2px; padding-left: 14px; color: #e2e8f0; line-height: 1.2;">');
                pInList = true;
                pListType = "ol";
            }
            result.push('<li>' + textContent + '</li>');
            continue;
        }

        // GFM Tables
        if (trimmed.startsWith("|") && trimmed.endsWith("|")) {
            if (pInList) {
                closeList(result, pListType);
                pInList = false;
            }

            pInTable = true;
            pTableRows.push(trimmed);
            continue;
        } else if (pInTable) {
            closeTable(result, pTableRows);
            pInTable = false;
            pTableRows = [];
        }

        // Empty line
        if (trimmed === "") {
            closeListAndTable(result, pInList, pListType, pInTable, pTableRows);
            pInList = false;
            pInTable = false;
            // Ignore empty lines to reduce vertical whitespace gaps in QML RichText
            continue;
        }

        // Normal paragraph text
        closeListAndTable(result, pInList, pListType, pInTable, pTableRows);
        pInList = false;
        pInTable = false;

        let pText = parseInline(line);
        result.push('<div style="margin-top: 2px; margin-bottom: 2px; color: #e2e8f0; line-height: 1.25; font-size: 13px;">' + pText + '</div>');
    }

    closeListAndTable(result, pInList, pListType, pInTable, pTableRows);
    return result.join("\n");
}

function closeListAndTable(result, inList, listType, inTable, tableRows) {
    if (inList) {
        closeList(result, listType);
    }
    if (inTable) {
        closeTable(result, tableRows);
    }
}

function closeList(result, listType) {
    result.push('</' + listType + '>');
}

function closeTable(result, tableRows) {
    if (tableRows.length === 0) return;

    let tableHtml = '<table style="border-collapse: collapse; width: 100%; margin-top: 4px; margin-bottom: 4px; border: 1px solid rgba(255,255,255,0.08); font-size: 12px; color: #cbd5e1;">';
    
    let rowData = [];
    for (let r = 0; r < tableRows.length; r++) {
        let cols = tableRows[r].split("|").map(s => s.trim()).filter((s, idx, arr) => idx > 0 && idx < arr.length - 1);
        rowData.push(cols);
    }

    let hasHeader = false;
    if (rowData.length > 1) {
        let secondRow = rowData[1];
        let isSep = secondRow.every(c => /^[-:\s]+$/.test(c));
        if (isSep) {
            hasHeader = true;
        }
    }

    if (hasHeader) {
        tableHtml += '<tr style="background-color: rgba(255,255,255,0.04); font-weight: bold;">';
        let headers = rowData[0];
        for (let h = 0; h < headers.length; h++) {
            tableHtml += '<th style="border: 1px solid rgba(255,255,255,0.08); padding: 4px 6px; text-align: left;">' + parseInline(headers[h]) + '</th>';
        }
        tableHtml += '</tr>';

        for (let r = 2; r < rowData.length; r++) {
            let rowBg = r % 2 === 0 ? 'background-color: rgba(255,255,255,0.02);' : '';
            tableHtml += '<tr style="' + rowBg + '">';
            let cols = rowData[r];
            for (let c = 0; c < cols.length; c++) {
                tableHtml += '<td style="border: 1px solid rgba(255,255,255,0.08); padding: 4px 6px;">' + parseInline(cols[c]) + '</td>';
            }
            tableHtml += '</tr>';
        }
    } else {
        for (let r = 0; r < rowData.length; r++) {
            let rowBg = r % 2 === 0 ? 'background-color: rgba(255,255,255,0.02);' : '';
            tableHtml += '<tr style="' + rowBg + '">';
            let cols = rowData[r];
            for (let c = 0; c < cols.length; c++) {
                tableHtml += '<td style="border: 1px solid rgba(255,255,255,0.08); padding: 4px 6px;">' + parseInline(cols[c]) + '</td>';
            }
            tableHtml += '</tr>';
        }
    }

    tableHtml += '</table>';
    result.push(tableHtml);
}

function parseInline(text) {
    if (!text) return "";

    // 1. Inline code blocks
    text = text.replace(/`([^`\n]+)`/g, '<code style="font-family: monospace; background-color: rgba(255,255,255,0.08); padding: 2px 4px; border-radius: 4px; color: #fb7185;">$1</code>');

    // 2. Bold
    text = text.replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>');
    text = text.replace(/__([^_]+)__/g, '<b>$1</b>');

    // 3. Italic
    text = text.replace(/\*([^*]+)\*/g, '<i>$1</i>');
    text = text.replace(/_([^_]+)_/g, '<i>$1</i>');

    // 4. Strikethrough
    text = text.replace(/~~([^~]+)~~/g, '<s>$1</s>');

    // 5. Links
    text = text.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" style="color: #c084fc; text-decoration: none;">$1</a>');

    // 6. Images
    text = text.replace(/!\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" style="color: #c084fc; text-decoration: none;">🖼 $1</a>');

    return text;
}
