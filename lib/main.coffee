###

Regex Builder

Sep 2013 ys

###

$window = $(window)
$exp = $('#exp')
$exp_dsp = $('#exp_dsp')
$txt = $('#txt')
$match = $('#match')
$flags = $('#flags')

is_paste = false

init = ->
	# Local storage.
	load_data()
	$window.on('beforeunload', save_data)

	on_window_resize()
	$window.resize(on_window_resize)

	# After data loaded, run once.
	run_match()

	init_key_events()
	init_bind()

	# Init tooltips.
	$('[title]').tooltip()

	# Focus on the expression input.
	setTimeout(
		-> $exp.select()
		500
	)

	init_affix()

	init_hide_switches()

init_key_events = ->
	# Edit change
	$txt.keydown(override_return)
	$exp.keydown(override_return)

	$txt.keyup(delay_run_match)
	$exp.keyup(delay_run_match)

	$txt.on('paste', -> is_paste = true)

	$flags.keyup(delay_run_match)

	$exp_dsp.click(select_all_text)

init_affix = ->
	$af = $('.affix')
	$ap = $('.affix-placeholder')
	$ap.height($af.outerHeight())
	$window.scroll(->
		$ap.height($af.outerHeight())
	)

init_bind = ->
	$('[bind]').each(->
		$this = $(this)
		window[$this.attr('bind')] = $this.val()

		$this.change(->
			window[$this.attr('bind')] = $this.val()
		)
	)

init_hide_switches = ->
	$('.switch_hide').click(->
		$this = $(this)
		$tar = $('#' + $this.attr('target'))

		if $this.prop('checked')
			$tar.hide()
		else
			$tar.show()
	)

on_window_resize = ->
	if $window.width() < 768
		$('.col-xs-8').removeClass('col-xs-8').addClass('col-xs-12')
		$('.col-xs-2').removeClass('col-xs-2').addClass('col-xs-6')
	else
		$('.col-xs-12').removeClass('col-xs-12').addClass('col-xs-8')
		$('.col-xs-6').removeClass('col-xs-6').addClass('col-xs-2')

delay_id = null
delay_run_match = ->
	elem = this
	clearTimeout(delay_id)
	delay_id = setTimeout(
		->
			if elem.id == 'txt' or elem.id == 'exp'
				saved_sel = saveSelection(elem)

			run_match()

			if elem.id == 'txt' or elem.id == 'exp'
				restoreSelection(elem, saved_sel)
		window.exe_delay
	)

# Generate tag for highlighting in turns.
anchor_c = 0
anchor = (index) ->
	c = anchor_c++ % 4
	switch c
		when 0
			"<i index='#{index}'>"
		when 1
			"</i>"
		when 2
			"<b index='#{index}'>"
		when 3
			"</b>"

# Escape html.
entityMap = {
	"&": "&amp;"
	"<": "&lt;"
	">": "&gt;"
}
escape_exp = /[&<>]/g
escape_html = (str) ->
	return String(str).replace(
		escape_exp,
		(s) ->
			return entityMap[s]
	)

select_all_text = ->
	if document.selection
		range = document.body.createTextRange()
		range.moveToElementText(this)
		range.select()
	else if window.getSelection
		range = document.createRange()
		range.selectNode(this)
		window.getSelection().addRange(range)

override_return = (e) ->
	if e.keyCode == 13
		document.execCommand('insertHTML', false, '\n')
		return false

run_match = ->
	# Clear other tags.
	$txt.find('div').remove()

	exp = $exp.text()
	flags = $flags.val()

	if is_paste
		$txt.html(
			clean_past_data($txt.html())
		)
		is_paste = false

	txt = $txt.text()


	if not exp
		input_clear()
		return

	try
		r = new RegExp(exp, flags)
	catch e
		input_clear(e)
		return

	syntax_highlight(exp, flags)

	# Store the match groups
	ms = []

	is_txt_shown = $txt.is(":visible")
	is_match_shown = $match.is(":visible")

	# Highlighting match words.
	visual = ''
	count = 0
	if r.global
		i = 0
		while (m = r.exec(txt)) != null
			ms.push m[0]
			k = r.lastIndex
			j = k - m[0].length

			if is_txt_shown
				visual += match_visual(txt, i, j, k, count++)

			i = k

			# Empty match will also increase the counter.
			if m[0].length == 0
				r.lastIndex++
	else
		txt.replace(r, (m) ->
			for i in [0 ... arguments.length - 2]
				ms.push arguments[i]

			i = 0
			j = arguments[arguments.length - 2]
			k = j + m.length

			if is_txt_shown
				visual += match_visual(txt, i, j, k, count++)

			i = k
		)

	if is_txt_shown
		visual += escape_html(txt.slice(i))

		$txt.empty().html(visual)

		$txt.find('[index]').hover(
			match_elem_show_tip
			->
				$(this).popover('destroy')
		)

	# Show the match object as json string.
	if is_match_shown
		list = create_match_list(ms)
		$match.html(list)

match_visual = (str, i, j, k, c) ->
	# Escaping is important.
	escape_html(str.slice(i, j)) +
	anchor(c) +
	escape_html(str.slice(j, k)) +
	anchor()

input_clear = (err) ->
	if err
		msg = err.message.replace('Invalid regular expression: ', '')
		$exp_dsp.html("<span class='error'>#{msg}</span>")
	else
		$exp_dsp.text('')

	$match.text('')
	$txt.text($txt.text())

clean_past_data = (txt) ->
	txt.replace(/<br[^>]+?>/ig, '\n')

syntax_highlight = (exp, flags) ->
	exp_escaped = exp.replace(/\\\//g, '/').replace(/\//g, '\\/')
	$exp_dsp.text("/#{exp_escaped}/#{flags}")

	exp = RegexColorizer.colorizeText(exp)
	$exp.html(exp)

create_match_list = (m) ->
	list = '<ol start="0">'
	if m
		for i in m
			es = escape_html(i)
			list += "<li><span class='g'>#{es}</span></li>"
	list += '</ol>'
	list

match_elem_show_tip = ->
	$this = $(this)

	index = $this.attr('index')

	# Create match list.
	reg = new RegExp($exp.text(), $flags.val().replace('g', ''))
	m = $this.text().match(reg)

	$this.popover({
		html: true
		title: 'Group: ' + index
		content: create_match_list(m)
		placement: 'bottom'
	}).popover('show')

save_data = (e) ->
	$('[save]').each(->
		$this = $(this)
		$this.find('.popover').remove()
		val = $this[$this.attr('save')]()

		localStorage.setItem(
			$this.attr('id'),
			val
		)
	)
	e.preventDefault()

load_data = ->
	# Load data.
	$('[save]').each(->
		$this = $(this)
		v = localStorage.getItem(
			$this.attr('id')
		)
		if v != null
			$this[$this.attr('save')](v)

	)

window.share_state = ->
	data = {
		exp: $exp.text()
		flags: $flags.val()
		txt: $txt.text()
	}

	$('#share').val(JSON.stringify(data)).select()

window.apply_state = ->
	data = JSON.parse($('#share').val())
	$exp.text(data.exp)
	$flags.val(data.flags)
	$txt.text(data.txt)

	run_match()


`
if (window.getSelection && document.createRange) {
    saveSelection = function(containerEl) {
        var range = window.getSelection().getRangeAt(0);
        var preSelectionRange = range.cloneRange();
        preSelectionRange.selectNodeContents(containerEl);
        preSelectionRange.setEnd(range.startContainer, range.startOffset);
        var start = preSelectionRange.toString().length;

        return {
            start: start,
            end: start + range.toString().length
        }
    };

    restoreSelection = function(containerEl, savedSel) {
    	if (!savedSel) return;
        var charIndex = 0, range = document.createRange();
        range.setStart(containerEl, 0);
        range.collapse(true);
        var nodeStack = [containerEl], node, foundStart = false, stop = false;

        while (!stop && (node = nodeStack.pop())) {
            if (node.nodeType == 3) {
                var nextCharIndex = charIndex + node.length;
                if (!foundStart && savedSel.start >= charIndex && savedSel.start <= nextCharIndex) {
                    range.setStart(node, savedSel.start - charIndex);
                    foundStart = true;
                }
                if (foundStart && savedSel.end >= charIndex && savedSel.end <= nextCharIndex) {
                    range.setEnd(node, savedSel.end - charIndex);
                    stop = true;
                }
                charIndex = nextCharIndex;
            } else {
                var i = node.childNodes.length;
                while (i--) {
                    nodeStack.push(node.childNodes[i]);
                }
            }
        }

        var sel = window.getSelection();
        sel.removeAllRanges();
        sel.addRange(range);
    }
} else if (document.selection && document.body.createTextRange) {
    saveSelection = function(containerEl) {
        var selectedTextRange = document.selection.createRange();
        var preSelectionTextRange = document.body.createTextRange();
        preSelectionTextRange.moveToElementText(containerEl);
        preSelectionTextRange.setEndPoint("EndToStart", selectedTextRange);
        var start = preSelectionTextRange.text.length;

        return {
            start: start,
            end: start + selectedTextRange.text.length
        }
    };

    restoreSelection = function(containerEl, savedSel) {
        var textRange = document.body.createTextRange();
        textRange.moveToElementText(containerEl);
        textRange.collapse(true);
        textRange.moveEnd("character", savedSel.end);
        textRange.moveStart("character", savedSel.start);
        textRange.select();
    };
}
`

init()