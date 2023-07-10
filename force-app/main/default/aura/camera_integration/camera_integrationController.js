({
    takePhoto : function(component, event, helper) {
        var constraints = { video: true };
        var video = document.querySelector('video');
        
        navigator.mediaDevices.getUserMedia(constraints)
        .then(function(stream) {
            video.srcObject = stream;
            video.play();
        })
        .catch(function(error) {
            console.error('Error accessing camera: ', error);
        });
        
        var canvas = document.createElement('canvas');
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        canvas.getContext('2d').drawImage(video, 0, 0);
        
        var imageUrl = canvas.toDataURL('image/png');
        component.set("v.imageUrl", imageUrl);
    }
})