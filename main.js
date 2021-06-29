function fixAnimationOnPageLoad() {
  var c = document.getElementsByTagName('content-center')[0];
  function addAnim() {
      c.classList.add('animated')
      // Remove the listener, no longer needed
      c.removeEventListener('mouseover', addAnim);
  };
  // Listen to mouseover for the container
  c.addEventListener('mouseover', addAnim);
}

particlesJS.load('particles-js', 'assets/particlesjs-config.json', function() {
  console.log('callback - particles.js config loaded');
  let el = document.querySelector(".particles-js-canvas-el"); 
  el.setAttribute("width", window.innerWidth.toString());
});
fixAnimationOnPageLoad();