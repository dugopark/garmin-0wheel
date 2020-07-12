// Unit tests for Utils class
using Toybox.Test as Test;

using Utils;

(:test)
function getHexValTest(logger) {
    Test.assertEqual(0, Utils.getHexVal('0'));
    Test.assertEqual(1, Utils.getHexVal('1'));
    Test.assertEqual(2, Utils.getHexVal('2'));
    Test.assertEqual(3, Utils.getHexVal('3'));
    Test.assertEqual(4, Utils.getHexVal('4'));
    Test.assertEqual(5, Utils.getHexVal('5'));
    Test.assertEqual(6, Utils.getHexVal('6'));
    Test.assertEqual(7, Utils.getHexVal('7'));
    Test.assertEqual(8, Utils.getHexVal('8'));
    Test.assertEqual(9, Utils.getHexVal('9'));
    Test.assertEqual(10, Utils.getHexVal('A'));
    Test.assertEqual(11, Utils.getHexVal('B'));
    Test.assertEqual(12, Utils.getHexVal('C'));
    Test.assertEqual(13, Utils.getHexVal('D'));
    Test.assertEqual(14, Utils.getHexVal('E'));
    Test.assertEqual(15, Utils.getHexVal('F'));
    return true;
}

(:test)
function stringToByteArrayTest(logger) {
    // Uneven number of characters in the string
    Test.assert(Utils.stringToByteArray("ABE") == null);

    logger.debug("AB = " + Utils.stringToByteArray("AB"));
    Test.assertEqual([171]b, Utils.stringToByteArray("AB"));

    logger.debug("ABAC = " + Utils.stringToByteArray("ABAC"));
    Test.assertEqual([171, 172]b, Utils.stringToByteArray("ABAC"));

    logger.debug("ABAC01 = " + Utils.stringToByteArray("ABAC01"));
    Test.assertEqual([171, 172, 1]b, Utils.stringToByteArray("ABAC01"));

    logger.debug("ABAC91 = " + Utils.stringToByteArray("ABAC91"));
    Test.assertEqual([171, 172, 145]b, Utils.stringToByteArray("ABAC91"));
    return true;
}