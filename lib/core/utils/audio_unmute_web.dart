import 'dart:js' as js;

void resumeWebAudio() {
  try {
    js.context.callMethod('eval', [
      "var resumeAudio = function() { "
      "  var AudioContext = window.AudioContext || window.webkitAudioContext; "
      "  if (AudioContext) { "
      "    var dummyContext = new AudioContext(); "
      "    if (dummyContext.state === 'suspended') { "
      "      dummyContext.resume(); "
      "    } "
      "  } "
      "  var dummyAudio = new Audio(); "
      "  dummyAudio.src = 'data:audio/wav;base64,UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAEA'; "
      "  dummyAudio.play().catch(function(){}); "
      "}; "
      "resumeAudio(); "
    ]);
  } catch (_) {}
}
