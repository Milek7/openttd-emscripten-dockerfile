Module['arguments'] = ['-d', '1'];

Module.preRun.push(function() {
	FS.createFolder('/', 'save', true, true);
	FS.mount(IDBFS, {}, '/save');

	FS.syncfs(true, function (err) { });

	window.save_data = function() {
		FS.syncfs(function (err) {});
	}
});
