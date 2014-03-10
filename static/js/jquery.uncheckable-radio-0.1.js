/**
 * JQuery uncheckable radio plugin
 *
 * This plugin allow to unckeck radio buttons. Just call the plugin like this :
 *
 * jQuery('input[type="radio"]').uncheckable();
 *
 * It also add handlers on associated labels.
 *
 * @name jquery.uncheckable-radio-0.1.js
 * @author Benoit Chenu <bchenu@gaya.fr>
 * @copyright Copyright (c) 2002-2011 GAYA - La nouvelle agence - http://www.gaya.fr/
 * @version 0.1
**/

(function($){

	$.fn.extend({
		uncheckable : function() {
			return this.each(function() {
				var $this = $(this);

				$this.mousedown($this.ucr_getRadioSatus);
				$this.click($this.ucr_setRadioSatus);

				// Associated label with "for" attribute
				if ($this.attr('id'))
				{
					$('label[for="'+$this.attr('id')+'"]').mousedown(function() {
						$this.ucr_getRadioSatus();
					});
					/* Automatically called
					$('label[for="'+$this.attr('id')+'"]').click(function() {
						$this.ucr_setRadioSatus();
					});
					*/
				}

				// Associated label defined as parent tag
				$this.parents('label').each(function() {
					// Check if handlers already defined
					if ($this.attr('id') && $(this).attr('for') == $this.attr('id'))
						return;

					$(this).mousedown(function() {
						$this.ucr_getRadioSatus();
					});
					/* Automatically called
					$(this).click(function() {
						$this.ucr_setRadioSatus();
					});
					*/
				});
			});

		},

		ucr_getRadioSatus : function() {
			_this = $(this).get(0);
			_this.ucr_checked = $(_this).attr('checked');
		},

		ucr_setRadioSatus : function() {
			_this = $(this).get(0);
			if (_this.ucr_checked)
			{
				_this.ucr_checked = false;
				$(_this).attr('checked', _this.ucr_checked);
			}
		}
	});
})(jQuery);;