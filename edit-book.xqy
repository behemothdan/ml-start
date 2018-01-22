xquery version "1.0-ml";
declare option xdmp:output "method = html";

declare function local:loadbook($searchQuery) {
    (cts:search(fn:collection()/book,
        cts:and-query((        
            cts:element-attribute-value-query(xs:QName('book'), xs:QName('id'), $searchQuery)
        ))
    ))
};

declare function local:updatebook() as xs:boolean {
    let $id as xs:string? := local:sanitizeInput(xdmp:get-request-field("id"))

    let $updatecheck as xs:boolean? := if($id) then (
        fn:true()
    ) else (
        fn:false()
    )

    let $book := local:loadbook($id)
    
    let $title as xs:string? := local:sanitizeInput(xdmp:get-request-field("title"))
    let $author as xs:string? := local:sanitizeInput(xdmp:get-request-field("author"))
    let $year as xs:string? := local:sanitizeInput(xdmp:get-request-field("year"))
    let $price as xs:string? := local:sanitizeInput(xdmp:get-request-field("price"))
    let $category as xs:string? := local:sanitizeInput(xdmp:get-request-field("category"))    

    let $tempbook := element book {
      $book/@*[fn:not(fn:local-name(.) eq 'category')],
      attribute category {
          $category
      },
      element title {
        $title
      },
      element author {
        $author
      },
      element year {
        $year
      },
      element price {
        $price
      }
    }
    let $baseuri := fn:base-uri($book)
    let $updatestatus := (if (xdmp:get-request-method() eq "POST" and $updatecheck) then (
        let $update := xdmp:document-insert($baseuri, $tempbook)
        return fn:true()
    ) else ())

    return $updatestatus
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
        <title>Update Books</title>
        <link rel="stylesheet" type="text/css" href="main.css" />
    </head>
    <body>  
        <div id="main">       
            <h1>Update Book</h1>
            {
                if (xdmp:get-request-method() eq "POST") then (                    
                    let $success := local:updatebook()
                    return if($success) then (
                        <div class="alert-success">Book updated! <a href="find-book.xqy">View more books!</a></div>
                    ) else (
                        <div class="alert-error">Book not saved. Sad face.</div>
                    )
                ) else ()
            }

            {                
                let $queryparams := local:getQueryString()
                let $book := local:loadbook($queryparams)
                
                return(                                
                    <form method="post" action="edit-book.xqy" class="bookupdate">                
                        <fieldset>                    
                            <label for="title">Title</label> <input type="text" id="title" name="title" value="{$book/title/text()}"/><br />
                            <label for="author">Author</label> <input type="text" id="author" name="author" value="{$book/author/text()}"/><br />
                            <label for="year">Year</label> <input type="text" id="year" name="year" value="{$book/year/text()}"/><br />
                            <label for="price">Price</label> <input type="text" id="price" name="price" value="{$book/price/text()}"/><br />
                            <label for="category">Category</label>                                                
                            <select name="category" id="category" class="{$book/@category}">
                                <option/>
                                {
                                    for $c in ('CHILDREN','FICTION','NON-FICTION')
                                    return if ($c eq $book/@category) then (
                                        <option value="{$c}" selected="true">{$c}</option>
                                    ) else (
                                        <option value="{$c}">{$c}</option>
                                    )
                                }
                            </select>
                            <input type="hidden" id="id" name="id" value="{local:getQueryString()}"/>
                            <input type="submit" value="Update"/>
                        </fieldset>                                                                 
                    </form>                    
                )
            }
        </div>
    </body>
</html>