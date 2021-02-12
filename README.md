# Objetiva

Objetiva is a plugin for the [Kakoune](http://kakoune.org/) editor that defines some new [object selections](https://github.com/mawww/kakoune/blob/master/doc/pages/keys.asciidoc#object-selection).

## Line object

A line object is defined with the command `objetiva-line`. You may wonder why a line object is needed if we already have the `x` key. Well, the `x` key defines a *movement* whereas `objetiva-line` defines an *object selection*, allowing you to select, for instance, an *inner line* (a line without the surrounding whitespaces), or select to the line end using the `]` key (instead of having to learn yet another key combination like `Gl`).

Also, if you are in an empty line, the `x` key moves the cursor to the *next line* instead of staying in the current one. This command, on the other hand, makes the cursor stays in the current line. 

Suggested mapping:

```
map global object x '<a-;>objetiva-line<ret>' -docstring line
```

That mapping allows you to select a line with `<a-a>x`, or select to the inner line start with `<a-[>x`

## Matching object

A matching object is like the `m` key for object selections. The command `objetiva-matching` selects the text enclosed by matching characters (respecting the built-in option `matching_pairs`).

Suggested mapping:

```
map global object m '<a-;>objetiva-matching<ret>' -docstring matching
```

Now, you can use, say, `<a-i>m` to select everything enclosed by parentheses.

## Case object

The command `objetiva-case` selects a segment of a word written in any of the following conventions: camelCase, snake_case and kebab-case.

Suggested mapping:

```
map global object - '<a-;>objetiva-case<ret>' -docstring case
```

Now you can use `<a-a>-` to select a segment of a word.

## Case movement

Although not an object selection, this plugin also defines commands for a *case movement* since it comes in handy. If you define the following mappings:

```
map global normal <minus> ': objetiva-case-move<ret>'
map global normal _ ': objetiva-case-expand<ret>'
map global normal <a-minus> ': objetiva-case-move-previous<ret>'
map global normal <a-_> ': objetiva-case-expand-previous<ret>'
```

You can move between segments of words in the forward direction using `<minus>` and in the backward direction using `<a-minus>`. You can also expand selection in the forward direction using `_` and in the backward direction using `<a-_>`.

## Instalation

Objetiva depends on the [luar](https://github.com/gustavo-hms/luar) plugin. If you use [plug.kak](https://github.com/robertmeta/plug.kak) to manage your plugins, you can install both by adding the following to your `kakrc`:

```
plug "gustavo-hms/luar" %{
    plug "gustavo-hms/objetiva"
}
```
