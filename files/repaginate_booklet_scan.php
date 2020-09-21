<?php
// Original author Carsten Jensen aka Tomse
// Copyright (c) 2013 Carsten Jensen
// Released under GNU GPL v2
// Modified by Martin Sørensen, 2020

// Corrects page numbers from scanned full-paper pages
// which has been split into 2, and been edited in scan tailor

if (count($argv) < 3) {
	echo("Missing parameter(s)\n");
	exit();
}
$sourcedir = $argv[1];
$targetdir = $argv[2];
$up = "0"; // set to 0 if back page lies first, or 1 if frontpage lies first
if (count($argv)>3 && $argv[3]=="1") $up = "1";
if (substr($sourcedir,strlen($sourcedir)-1) != DIRECTORY_SEPARATOR) $sourcedir=$sourcedir.DIRECTORY_SEPARATOR;
if (substr($targetdir,strlen($targetdir)-1) != DIRECTORY_SEPARATOR) $targetdir=$targetdir.DIRECTORY_SEPARATOR;

$wildcard = $sourcedir.'*.[pP][dD][fF]';
$files = glob($wildcard,GLOB_BRACE);
natsort($files);
$down = count($files);
$pad = strlen($down)+1;
@mkdir($targetdir);

$again = 1;
$back = ($up == "0") ? true : false;
foreach($files as $k => $v)
{
	$ext = substr($v,strrpos($v,"."));
	if($back === true)
	{
		$outfilename = $targetdir . 'page' . padding($down, $pad) . $ext;
		$down--;
		if ($again > 2 OR $k == 0)
		{
			$again = 1;
			$back = false;
		}
		$again++;
	}
	else
	{
		$outfilename = $targetdir . 'page' . padding($up, $pad) . $ext;
		$up++;
		if ($again > 2)
		{
			$again = 1;
			$back = true;
		}
		$again++;
	}
	echo "$v => $outfilename\n";
	copy($v, $outfilename);
}

/**
 * Pads a number with zeroes to make a nice even lenghted result
 * Author Carsten Jensen
 * @param int $int number to be padded
 * @param int $length of padding
 * @return int padded number
*/
function padding($int, $length = 2)
{
	return str_pad($int, $length, 0, STR_PAD_LEFT);
}
?>