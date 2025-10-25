var Action = function() {};

Action.prototype = {
  run : function(arguments) {
    // Extract the full HTML content
    var html = document.documentElement.outerHTML;

    // You can also grab other info if needed:
    var title = document.title;
    var url = window.location.href;

    // Pass it back to Swift
    arguments.completionFunction({"html" : html, "title" : title, "url" : url});
  }
}

var ExtensionPreprocessingJS = new Action();
