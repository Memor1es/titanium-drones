$(function() {
    var audioPlayer = null;

    window.addEventListener('message', function(event) {
        if (event.data.type == "updateHUD") {
            var drone_HUD = document.getElementById("drone_hud");

            var speed_HUD = document.getElementById("speed_display");
            var height_HUD = document.getElementById("height_display");
            var signal_HUD = document.getElementById("signal_display");

            if(drone_HUD.style.opacity == 0.0){
                drone_HUD.style.opacity = 1.0;
            }

            speed_HUD.innerHTML = "Speed: "+event.data.speed+" KM/h";
            height_HUD.innerHTML = "Height: "+event.data.height+" ft";
            signal_HUD.innerHTML = "Signal: "+event.data.signal;
        } else if (event.data.type == "closeHUD"){
            var drone_HUD = document.getElementById("drone_hud");
            this.console.log("test")
            drone_HUD.style.opacity = 0.0;
        } else if (event.data.type == "playSound"){
            if (audioPlayer != null) {
                audioPlayer.pause();
            }
            audioPlayer = new Howl({src: ["sounds/whistle.ogg"]});
            audioPlayer.volume(event.data.phoneVolume);
            audioPlayer.play()
        }
    });
});
