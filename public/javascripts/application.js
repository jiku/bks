// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function setY()
{
	var headerHeight = document.getElementById('header').offsetHeight;
	var leftHeight = document.getElementById('left').offsetHeight;
	var rightHeight = document.getElementById('right').offsetHeight;
	var footerHeight = document.getElementById('footer').offsetHeight;

	var leftMinimumHeight = window.innerHeight - (headerHeight + footerHeight);
	if(leftHeight < leftMinimumHeight) {
		document.getElementById('left').style.height = (leftMinimumHeight - 47) + "px"; // 48 er samlet padding t+b til left
		leftHeight = document.getElementById('left').offsetHeight;
	}
	
	document.getElementById('right').style.height = leftHeight + "px";

	var footerPosition = headerHeight + leftHeight;
	
	document.getElementById('footer').style.top = footerPosition + "px";
	
	var edgeHeight = (footerPosition + document.getElementById('footer').offsetHeight);
	document.getElementById('edgeLeft').style.height = edgeHeight + "px";
	document.getElementById('edgeRight').style.height = edgeHeight + "px";
}

/*
var i = 0;
var testarray = new Array;
testarray[0] = "Kapasitet<br/> 120 linjer";
testarray[1] = "Befolkningsvarsling";
testarray[2] = "Vaktinnkalling";
testarray[3] = "Automatisk tekst-til-tale";

function initReklame()
{
	Effect.Fade('reklame_tekst', {duration: 2.0, delay: 4.0});
	Element.hide("reklame_tekst");
	i = i%testarray.length;
	$("reklame_tekst").innerHTML="<b>" + testarray[i] + "</b>";
	i+=1;
	Effect.Appear('reklame_tekst', {duration: 2.0});
}
*/

Event.observe(window, 'load', function() {
	setY();
	initReklame();
    setInterval(initReklame, 8000);
});