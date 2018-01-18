xquery version "1.0-ml";

declare option xdmp:output "method = html";

declare function local:searchBooks($searchQuery) {
    (cts:search(fn:collection()/book,
        cts:or-query((
            cts:element-value-query((xs:QName('title'), xs:QName('author'), xs:QName('year'), xs:QName('price')), fn:string-join(("* ", $searchQuery, " *")), ("wildcarded", "case-insensitive", "punctuation-insensitive")),
            cts:element-attribute-value-query(xs:QName('book'), xs:QName('category'), $searchQuery, ("case-insensitive", "whitespace-insensitive"))
        ))
    ))
};

declare function local:getQueryString() {
    let $originalurl := xdmp:get-original-url()
    let $queryparams := fn:substring-after($originalurl, '?q=')
    return $queryparams
};

declare function local:sanitizeInput($chars as xs:string?) {
    fn:replace($chars,"[\]\[<>{}\\();%\+]","")
};

xdmp:set-response-content-type("text/html"),
'<!DOCTYPE html>',
<html lang="en">
    <head>
        <title>Find Books</title>
        <link rel="stylesheet" type="text/css" href="main.css" />
    </head>
    <body>  
        <div id="main">       
            <h1>Search Books</h1>
            <form method="get" action="find-book.xqy" class="booksearch">
                <fieldset>
                    <input type="text" id="q" name="q" placeholder="What do you want to read?" autofocus="true"/>                    
                </fieldset>
            </form>
            {                     
                let $queryparams := local:getQueryString()

                let $books := local:searchBooks($queryparams)
                let $searchcount := fn:count($books)    

                return if($searchcount > 0) then                
                    for $book in $books return (
                        <div class="book" id="{$book/@id/string()}">                        
                            <span class="booktitle">{$book/title/text()}</span>
                            <span class="category">{$book/@category/string()}</span>
                            <div class="details">
                                <span>{$book/author/text()}</span>
                                <span>Year: {$book/year/text()}</span>
                                <span>${$book/price/text()}</span>         
                                <span class="editlink"><a href="edit-book.xqy?q={$book/@id/string()}">Edit</a></span>          
                            </div>
                        </div>                    
                ) else (
                    <div class="book">No results found. Broaden your horizons or broaden our <a href="add-book.xqy">database</a>!</div>
                )
            }
        </div>
    </body>
</html>