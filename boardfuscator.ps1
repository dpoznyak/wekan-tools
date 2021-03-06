function Obfuscate-Board {
    [CmdLetBinding()]
    param (
        [string]$Path
    )

    $board = (gc $Path -encoding utf8) | convertfrom-json;

    write-debug "Board: $board";

    foreach ($label in $board.labels) {
        Obfuscate-Property -Property "name" -Object $label
        Obfuscate-Property -Property "altName" -Object $label
    }
    foreach ($card in $board.cards) {
        Obfuscate-Property -Property "title" -Object $card
        Obfuscate-Property -Property "description" -Object $card
    }
    foreach ($comment in $board.comments) {
        Obfuscate-Property -Property "text" -Object $comment
    }
    foreach ($checklist in $board.checklists) {
        Obfuscate-Property -Property "title" -Object $checklist
        foreach ($item in $checklist.items) {
            Obfuscate-Property -Property "title" -Object $item
        }
    }

    $board.slug = $board.slug + "_obfu";
    $board.title = $board.title + " [obfu]";

    $board | convertto-json -Depth 99 | set-content -encoding utf8 "$Path.obfuscated.json"

    # labels.*.name
    # labels.*.altName
    # cards.*.title
    # cards.*.description
    # comments.*.text
    # checklists.*.title
    # checklists.*.items.*.title

    # attachments.*.file ?
    }
function Obfuscate-String {
    param ([string]$Value)
    # replace letters with random letters
    # .. unless special: emoji, ..?

    # $matches = [Regex]::Matches($Value, "((.*?\w+)*(\:\w+\:)*)*")
    return [Regex]::Replace($Value, "(?<!\:\w*)\w", "x", [System.Text.RegularExpressions.RegexOptions]::SingleLine + [System.Text.RegularExpressions.RegexOptions]::Multiline);
    
    
}

Describe "Obfuscate-string" {
    It "Given '<Value>', returns '<Expected>'" -TestCases @(
            @{ Value="Simple string"; Expected="xxxxxx xxxxxx"}
            @{ Value="Simple :bulb: string"; Expected="xxxxxx :bulb: xxxxxx"}
            @{  
                Value=      "@санаторий получить историю +фикс +fu claim #x :o: ``recordenquiry``:email:"; 
                Expected=   "@xxxxxxxxx xxxxxxxx xxxxxxx +xxxx +xx xxxxx #x :o: ``xxxxxxxxxxxxx``:email:"
            }
            @{  
                Value=@'
@санаторий 
* получить историю +фикс +fu claim #x :o::bulb: `recordenquiry`:email:
'@; 
                Expected=@'
@xxxxxxxxx 
* xxxxxxxx xxxxxxx +xxxx +xx xxxxx #x :o::bulb: `xxxxxxxxxxxxx`:email:
'@
            } 
            @{ Value=":emoji:жопа"; Expected=":emoji:xxxx"} 
            ) {
        param ($Value, $Expected)

        (Obfuscate-String $Value) | Should -Be $Expected
 
    }

}
function Obfuscate-Property {
    param ([string]$Property, $Object) 
    
    $v = $Object.$Property;
    if ($v) {
        $r = Obfuscate-String $v;
        if ($r) {
            $Object.$Property = $r;
        }
    }

}

Describe "Obfuscate-Property" {

    Context "When manipulating json objects" {

        function act {
            param ($prop)
            $json = '{"key": "value value"}';
            $jsonO = $json | convertfrom-json;

            Obfuscate-Property -Property $prop -Object $jsonO;

            return $resultingJson = $jsonO | ConvertTo-Json -Depth 99 -Compress
        }

        
        Context "For existing property" {
            It "Should obfuscate" { act "key" | should -be '{"key":"xxxxx xxxxx"}' }
        }
        Context "For missing property" {
            It "Should ignore" { act "key nonex" | should -be '{"key":"value value"}' }
        }

    }
}