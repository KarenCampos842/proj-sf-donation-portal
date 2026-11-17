@IsTest
private class PublicNameSanitizerTest {
    @IsTest
    static void shouldKeepName_WhenItHasNoMarkup() {
        Assert.areEqual('Familia Pérez', PublicNameSanitizer.sanitize('Familia Pérez'), 'A plain name is not changed');
    }

    @IsTest
    static void shouldRemoveTags_WhenNameContainsScriptTag() {
        Assert.areEqual('alert(1)', PublicNameSanitizer.sanitize('<script>alert(1)</script>'), 'Tags are removed, the text between them stays');
    }

    @IsTest
    static void shouldKeepWordsApart_WhenTagsSeparateThem() {
        Assert.areEqual('Ana López Ruiz', PublicNameSanitizer.sanitize('Ana<b>López</b> Ruiz'), 'A removed tag leaves a space');
    }

    @IsTest
    static void shouldRemoveTagAttributes_WhenTagHasThem() {
        Assert.areEqual('Ana', PublicNameSanitizer.sanitize('<a href="x" onclick="y">Ana</a>'), 'Attributes go with the tag');
    }

    @IsTest
    static void shouldRemoveAngleBrackets_WhenTagIsNeverClosed() {
        Assert.areEqual('img src=x onerror=alert(1)', PublicNameSanitizer.sanitize('<img src=x onerror=alert(1)'), 'No angle bracket survives');
    }

    @IsTest
    static void shouldRemoveAngleBracket_WhenItDoesNotOpenATag() {
        Assert.areEqual('Ana 3 López', PublicNameSanitizer.sanitize('Ana <3 López'), 'Only the bracket is dropped');
    }

    @IsTest
    static void shouldRemoveClosingBracket_WhenItStandsAlone() {
        Assert.areEqual('Ana Luis', PublicNameSanitizer.sanitize('Ana > Luis'), 'A lone closing bracket is dropped');
    }

    @IsTest
    static void shouldReturnEmptyText_WhenNameIsOnlyMarkup() {
        for (String name : new List<String>{ '<b></b>', '<script></script>', '<br/>', '<<>>', '<>' }) {
            Assert.areEqual('', PublicNameSanitizer.sanitize(name), 'Only markup leaves nothing: ' + name);
        }
    }

    @IsTest
    static void shouldReturnEmptyText_WhenNameIsNullOrBlank() {
        for (String name : new List<String>{ null, '', '     ', '\t \n ' }) {
            Assert.areEqual('', PublicNameSanitizer.sanitize(name), 'No text to keep: ' + name);
        }
    }

    @IsTest
    static void shouldCollapseSpacesAndControlCharacters_WhenNameHasThem() {
        Assert.areEqual('Familia Pérez López', PublicNameSanitizer.sanitize('  Familia \t Pérez\n López  '), 'Spaces are normalized');
    }

    @IsTest
    static void shouldGiveSameResult_WhenSanitizedTwice() {
        String once = PublicNameSanitizer.sanitize('<b>Ana</b> <3 <i>López');
        Assert.areEqual(once, PublicNameSanitizer.sanitize(once), 'Cleaning an already clean name changes nothing');
    }

    @IsTest
    static void shouldNotBeTooLong_WhenNameIsNull() {
        Assert.isFalse(PublicNameSanitizer.isTooLong(null), 'Null is handled by the required check, not the length check');
    }

    @IsTest
    static void shouldNotBeTooLong_WhenNameHasExactlyEightyCharacters() {
        Assert.isFalse(PublicNameSanitizer.isTooLong('a'.repeat(80)), 'The limit is inclusive');
    }

    @IsTest
    static void shouldBeTooLong_WhenNameHasEightyOneCharacters() {
        Assert.isTrue(PublicNameSanitizer.isTooLong('a'.repeat(81)), 'One character over the limit');
    }

    @IsTest
    static void shouldNotBeTooLong_WhenMarkupIsRemovedAndTheResultFitsTheLimit() {
        Assert.isFalse(PublicNameSanitizer.isTooLong('<b>' + 'a'.repeat(80) + '</b>'), 'The limit applies to the cleaned text');
    }

    @IsTest
    static void shouldBeTooLong_WhenCleanedTextExceedsTheLimit() {
        Assert.isTrue(PublicNameSanitizer.isTooLong('<b>' + 'a'.repeat(81) + '</b>'), 'The cleaned text has 81 characters');
    }

    @IsTest
    static void shouldBeTooLong_WhenRawTextExceedsTheRawLimit() {
        Assert.isTrue(PublicNameSanitizer.isTooLong(' '.repeat(PublicNameSanitizer.MAX_RAW_LENGTH + 1)), 'Oversized input is rejected before cleaning');
    }
}
