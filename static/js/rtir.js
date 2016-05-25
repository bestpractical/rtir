jQuery(function() {
    var getQueryString = function(element) {
        var href = jQuery(element).attr('href');
        if (!href) return '';
        var questionMarkIndex = href.indexOf('?');
        if (!questionMarkIndex) return '';
        return href.substring(questionMarkIndex+1);
    };

    var showModal = function(lifecycle, triggeringObject) {
        var queryString = getQueryString(triggeringObject);
        var constituency = '';

        var uri = window.location.href.split('/');
        for (var i = 0; i < uri.length; i++) {
            if (uri[i] === 'c') {
                constituency = '/c/' + uri[i+1];
                break;
            }
        }

        jQuery.get(
            RT.Config.WebHomePath + '/RTIR' + constituency + '/Helpers/CreateInRTIRQueueModal?Lifecycle=' + lifecycle + '&' + queryString,
            function(html) {
                // If there's only one queue, just create a ticket in it and skip the modal
                var queues = jQuery(html).find("select[name='Queue'] > option");
                if (queues.length === 1) {
                    window.location.href = RT.Config .WebHomePath + '/RTIR/Create.html?Queue=' + queues.first().val() + '&' + queryString;
                     return;
                }

                jQuery("<div class='modal'></div>")
                    .append(html).appendTo("body")
                    .bind('modal:close', function(ev,modal) { modal.elm.remove(); })
                    .modal();
            }
        );
    };

    var showReportsModal = function(e) {
        e.preventDefault();
        showModal('incident_reports', this);
    };

    var showInvestigationsModal = function(e) {
        e.preventDefault();
        showModal('investigations', this);
    };

    var showBlocksModal = function(e) {
        e.preventDefault();
        showModal('blocks', this);
    };

    var showIncidentsModal = function(e) {
        e.preventDefault();
        showModal('incidents', this);
    };

    jQuery('body').on('click', '#reports-create', showReportsModal);
    jQuery('body').on('click', '#investigations-launch', showInvestigationsModal);
    jQuery('body').on('click', '#blocks-create', showBlocksModal);
    jQuery('body').on('click', '#incidents-create', showIncidentsModal);
    jQuery('body').on('click', '#create-incident', showIncidentsModal);

    jQuery('body').on('click', '.create_child_incident_reports', showReportsModal);
    jQuery('body').on('click', '.create_child_investigations', showInvestigationsModal);
    jQuery('body').on('click', '.create_child_blocks', showBlocksModal);
});
