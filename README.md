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
