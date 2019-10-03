# jsonneD: Binding to jsonnet for the D Programming language

[jsonnet](https://jsonnet.org/)

```D
///
unittest {
	import std.json;
	JsonneD jn = JsonneD();
	string s = `
	{
		person1: {
			name: "Alice",
			welcome: "Hello " + self.name + "!",
		},
		person2: self.person1 {
			name: std.extVar("OTHER_NAME"),
		},
	}`;
	jn.extVar("OTHER_NAME", "Robert Schadek");

	auto eval = jn.evaluateSnippet("foo.json", s);
	JSONValue exp = parseJSON(`
	{
		"person1": {
			"name": "Alice",
			"welcome": "Hello Alice!"
		},
		"person2": {
			"name": "Robert Schadek",
			"welcome" : "Hello Robert Schadek!"
		}
	}`);

	assert(!eval.rslt.isNull);
	JSONValue r = parseJSON(eval.rslt.get());

	assert(exp == r, format("\nexp:\n%s\neva:\n%s", exp.toPrettyString(),
				r.toPrettyString()));
}
```

```D
///
unittest {
	import std.json;
	JsonneD jn = JsonneD();
	auto rs = jn.evaluteFileMulti("tests/m0.jsonnnet");
	assert(rs.length == 2, format("%s", rs.length));
	assert(rs[0].filename == "a.json");
	assert(rs[1].filename == "b.json");
}
```

```D
///
unittest {
	import std.json;
	string s = `
{
  "a.json": {
    x: 1,
    y: $["b.json"].y,
  },
  "b.json": {
    x: $["a.json"].x,
    y: 2,
  },
}
	`;
	JsonneD jn = JsonneD();

	auto rs = jn.evaluteSnippetMulti("foo.json", s);
	assert(rs.length == 2, format("%s", rs.length));
	assert(rs[0].filename == "a.json");
	assert(rs[1].filename == "b.json");
}
```

## Documentation
The Documentation is still WIP, please have a look at the vibe.d project in the
test folder.

## Contributing
PRs are welcome!

# About Kaleidic Associates
We are a boutique consultancy that advises a small number of hedge fund clients.  We are
not accepting new clients currently, but if you are interested in working either remotely
or locally in London or Hong Kong, and if you are a talented hacker with a moral compass
who aspires to excellence then feel free to drop me a line: laeeth at kaleidic.io

We work with our partner Symmetry Investments, and some background on the firm can be
found here:

http://symmetryinvestments.com/about-us/
