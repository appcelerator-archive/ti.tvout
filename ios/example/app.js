/*
 * TVOut Example Application
 *
 * This application demonstrates how to use the TVOut module to display output to an external monitor
 *
 * To run this application on the simulator
 *   1. Start the application
 *   2. Select 'Hardware' from the simulator's main menu
 *   3. Select 'TVOut' from the menu
 *   4. Select a resolution
 *
 * To run this application on device, connect an external monitor to your device
 *
 * The buttons near the top determine what is displayed on the external monitor:
 *   'Window': The application window is mirrored to the external monitor (default)
 *   'View': A separate background view is shown on the external monitor
 *   'Mirror': An active child view of the main application window is mirrored to the external monitor
 */

var TVOut = require('ti.tvout');

var started = false;

var viewForTV = Ti.UI.createView({
	backgroundColor: '#93d3ff'
});
var ball = Ti.UI.createView({
	backgroundColor: 'red',
	width: 60, height: 60, bottom: 0,
	borderRadius: 30
});
viewForTV.add(ball);

var viewMirror = Ti.UI.createWebView({
	url: 'http://www.appcelerator.com',
	top: 4,	left: 4, right: 4, height: 240
});

var tvStatus = Ti.UI.createLabel({
    text: 'TV Connected? ' + (TVOut.connected ? 'Yes!' : 'No!'),
    top: 4, height: Ti.UI.SIZE, width: Ti.UI.SIZE,
    textAlign: 'center'
});

var bounceTheBall = Ti.UI.createButton({
    title: 'Bounce The Ball',
    top: 4, width: 200, height: 50,
    color: 'black'
});

bounceTheBall.addEventListener('click', function() {
    var animation = Titanium.UI.createAnimation({
        bottom: 80, 
        duration: 300,
        curve: Ti.UI.ANIMATION_CURVE_EASE_IN_OUT
    });

    function goBack() {
        animation.removeEventListener('complete', goBack);
        animation.bottom = 0;
        animation.duration = 200;
        ball.animate(animation);
    }

    animation.addEventListener('complete', goBack);
    ball.animate(animation);
});

var toggleScreen = Ti.UI.createButton({
    title: started ? 'Stop TV' : 'Start TV',
    top: 4, width: 200, height: 50,
    color: 'black'
});

toggleScreen.addEventListener('click', toggleStart);

function toggleStart()
{
	setStarted(!started);
	if (started) {
		TVOut.start();
	} else {
		TVOut.stop();
	}
}

function setStarted(hasStarted) 
{
	started = hasStarted;
	toggleScreen.title = started ? 'Stop TV' : 'Start TV';
}

TVOut.addEventListener('connect', function() {
    tvStatus.text = 'TV Connected? Yes!';
});

TVOut.addEventListener('disconnect', function() {
    tvStatus.text = 'TV Connected? No!';
});

var tvViewState = Ti.UI.createLabel({
    text: 'Displaying Window',
    top: 4, height: Ti.UI.SIZE, width: Ti.UI.SIZE,
    textAlign: 'center'
});

var viewButtons = Ti.UI.createView({
    top: 4, width: 308,
	height: Ti.UI.SIZE
});

var btnWindow = Ti.UI.createButton({
	title: 'Window',
	left: 0, width: 100
});

var btnBackground = Ti.UI.createButton({
	title: 'View',
	width: 100
});

var btnMirror = Ti.UI.createButton({
	title: 'Mirror',
	right: 0, width: 100
});

viewButtons.add(btnWindow);
viewButtons.add(btnBackground);
viewButtons.add(btnMirror);
btnWindow.addEventListener('click', function() {
	tvViewState.text = 'Displaying Window';
	TVOut.setView();
	setStarted(true);
});
btnBackground.addEventListener('click', function() {
	tvViewState.text = 'Displaying View';
	TVOut.setView(viewForTV, false);
	setStarted(true);
});
btnMirror.addEventListener('click', function() {
	tvViewState.text = 'Displaying Mirror View';
	TVOut.setView(viewMirror, true);
	setStarted(true);
});

var window = Ti.UI.createWindow({
    backgroundColor: '#fff',
    layout: 'vertical'
});

window.add(tvStatus);
window.add(toggleScreen);
window.add(tvViewState);
window.add(viewButtons);
window.add(viewMirror);
window.add(bounceTheBall);

window.open();