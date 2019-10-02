module jsonned;

import binding;

struct JsonneD {
	import core.memory : pureFree, pureMalloc;
	import std.typecons : nullable, Nullable;
	import std.string : toStringz, fromStringz;

	JsonnetVm* vm;

	@disable this(this);

	static JsonneD opCall() {
		JsonneD ret;
		ret.vm = jsonnet_make();
		return ret;
	}

	~this() {
		if(this.vm !is null) {
			jsonnet_destroy(this.vm);
		}
	}

	void destroy() {
		jsonnet_destroy(this.vm);
		this.vm = null;
	}

	/** Set the maximum stack depth. */
	void setMaxStack(uint v) {
		jsonnet_max_stack(this.vm, v);
	}

	/** Set the number of objects required before a garbage collection cycle is allowed. */
	void setGCminObjects(uint v) {
		jsonnet_gc_min_objects(this.vm, v);
	}

	/** Run the garbage collector after this amount of growth in the number of objects. */
	void setGCgrowthTrigger(double v) {
		jsonnet_gc_growth_trigger(this.vm, v);
	}

	/** Expect a string as output and don't JSON encode it. */
	void expectStringOutput(bool v) {
		jsonnet_string_output(this.vm, v);
	}

	/** Clean up a JSON subtree.
	 *
	 * This is useful if you want to abort with an error mid-way through building a complex value.
	 */
	void jsonDestroy(JsonnetJsonValue *v) {
		jsonnet_json_destroy(this.vm, v);
	}

	struct JsonnetValue {
		struct Payload {
			JsonnetJsonValue* value;
			JsonneD* vm;
			long cnt;
		}

		Payload* payload;

		this(JsonnetJsonValue* value, JsonneD* vm) {
			this.payload = cast(Payload*)pureMalloc(Payload.sizeof);
			this.payload.cnt = 1;
			this.payload.vm = vm;
			this.payload.value = value;
		}

		this(this) {
			this.increment();
		}

		~this() {
			this.decrement();
		}

		private void increment() {
			if(this.payload) {
				this.payload.cnt++;
			}
		}

		private void decrement() {
			if(this.payload) {
				this.payload.cnt--;
				if(this.payload.cnt <= 0) {
					this.payload.vm.jsonDestroy(this.payload.value);
					pureFree(this.payload);
					this.payload = null;
				}
			}
		}

		void opAssign(JsonnetValue other) {
			other.increment();
			this.decrement();
			this.payload = other.payload;
		}

		/** If the value is a string, return it as UTF8 otherwise return NULL.
		 */
		Nullable!string extractString() {
			const char* str = jsonnet_json_extract_string(this.payload.vm.vm,
					this.payload.value);

			return str is null
				? Nullable!(string).init
				: nullable(str.fromStringz().idup);
		}

		/** If the value is a number, return 1 and store the number in out, otherwise return 0.
		 */
		Nullable!double extractNumber() {
			double o;
			bool worked = cast(bool)jsonnet_json_extract_number(
					this.payload.vm.vm, this.payload.value, &o);

			return worked ? nullable(o) : Nullable!(double).init;
		}

		/** Return 0 if the value is false, 1 if it is true, and 2 if it is not a bool.
		 */
		Nullable!bool extractBool() {
			int v = jsonnet_json_extract_bool(this.payload.vm.vm,
					this.payload.value);
			return v == 2 ? Nullable!(bool).init : nullable(cast(bool)v);
		}

		/** Return 1 if the value is null, else 0.
		 */
		bool extractNull() {
			return cast(bool)jsonnet_json_extract_null(this.payload.vm.vm,
					this.payload.value);
		}

		/** Add v to the end of the array.
		 */
		void arrayAppend(JsonnetValue v) {
			jsonnet_json_array_append(this.payload.vm.vm, this.payload.value,
					v.payload.value);
		}

		/** Add the field f to the object, bound to v.
		 *
		 * This replaces any previous binding of the field.
		 */
		void objectAppend(string f, JsonnetValue v) {
			jsonnet_json_object_append(this.payload.vm.vm, this.payload.value,
					toStringz(f), v.payload.value);
		}
	}

	/** Convert the given UTF8 string to a JsonnetJsonValue.
	 */
	JsonnetValue makeString(string v) {
		JsonnetJsonValue* t = jsonnet_json_make_string(this.vm, v.toStringz());
		return JsonnetValue(t, &this);
	}

	/** Convert the given double to a JsonnetJsonValue.
	 */
	JsonnetValue makeNumber(double v) {
		JsonnetJsonValue* t = jsonnet_json_make_number(this.vm, v);
		return JsonnetValue(t, &this);
	}

	/** Convert the given bool (1 or 0) to a JsonnetJsonValue.
	 */
	JsonnetValue makeBool(bool v) {
		JsonnetJsonValue* t = jsonnet_json_make_bool(this.vm, v);
		return JsonnetValue(t, &this);
	}

	/** Make a JsonnetJsonValue representing null.
	 */
	JsonnetValue makeNull() {
		JsonnetJsonValue* t = jsonnet_json_make_null(this.vm);
		return JsonnetValue(t, &this);
	}

	/** Make a JsonnetJsonValue representing an array.
	 *
	 * Assign elements with jsonnet_json_array_append.
	 */
	JsonnetValue makeArray() {
		JsonnetJsonValue* t = jsonnet_json_make_array(this.vm);
		return JsonnetValue(t, &this);
	}

	/** Make a JsonnetJsonValue representing an object with the given number of
	 * fields.
	 *
	 * Every index of the array must have a unique value assigned with
	 * jsonnet_json_array_element.
	 */
	JsonnetValue makeObject() {
		JsonnetJsonValue* t = jsonnet_json_make_object(this.vm);
		return JsonnetValue(t, &this);
	}

	/** Override the callback used to locate imports.
	 */
	void importCallback(JsonnetImportCallback cb, void* ctx) {
		jsonnet_import_callback(this.vm, cb, ctx);
	}

	/** Register a native extension.
	 *
	 * This will appear in Jsonnet as a function type and can be accessed from std.nativeExt("foo").
	 *
	 * DO NOT register native callbacks with side-effects!  Jsonnet is a lazy functional language and
	 * will call your function when you least expect it, more times than you expect, or not at all.
	 *
	 * \param vm The vm.
	 * \param name The name of the function as visible to Jsonnet code, e.g. "foo".
	 * \param cb The PURE function that implements the behavior you want.
	 * \param ctx User pointer, stash non-global state you need here.
	 * \param params NULL-terminated array of the names of the params.  Must be valid identifiers.
	 */
	void nativeCallback(string name, JsonnetNativeCallback cb,
			void* ctx, const(char)** params)
	{
		jsonnet_native_callback(this.vm, cast(const(char)*)toStringz(name), cb,
				ctx, params);
	}

	/** Bind a Jsonnet external var to the given string.
	 *
	 * Argument values are copied so memory should be managed by caller.
	 */
	void extVar(string key, string val) {
		jsonnet_ext_var(this.vm, toStringz(key), toStringz(val));
	}

	/** Bind a Jsonnet external var to the given code.
	 *
	 * Argument values are copied so memory should be managed by caller.
	 */
	void extCode(string key, string val) {
		jsonnet_ext_code(this.vm, toStringz(key), toStringz(val));
	}

	/** Bind a string top-level argument for a top-level parameter.
	 *
	 * Argument values are copied so memory should be managed by caller.
	 */
	void tlaVar(string key, string val) {
		jsonnet_tla_var(this.vm, toStringz(key), toStringz(val));
	}

	/** Bind a code top-level argument for a top-level parameter.
	 *
	 * Argument values are copied so memory should be managed by caller.
	 */
	void tlaCode(string key, string val) {
		jsonnet_tla_code(this.vm, toStringz(key), toStringz(val));
	}

	/** Set the number of lines of stack trace to display (0 for all of them). */
	void maxTrace(uint v) {
		jsonnet_max_trace(this.vm, v);
	}

	/** Add to the default import callback's library search path.
	 *
	 * The search order is last to first, so more recently appended paths take precedence.
	 */
	void jpathAdd(string v) {
		jsonnet_jpath_add(this.vm, toStringz(v));
	}

	///
	struct JsonnetResult {
		Nullable!string rslt;
		string error;
	}

	/** Evaluate a file containing Jsonnet code, return a JSON string.
	 *
	 * The returned string should be cleaned up with jsonnet_realloc.
	 *
	 * \param filename Path to a file containing Jsonnet code.
	 * \param error Return by reference whether or not there was an error.
	 * \returns Either JSON or the error message.
	 */
	JsonnetResult evaluateFile(string filename) {
		int error;
		char* rslt = jsonnet_evaluate_file(this.vm, toStringz(filename), &error);
		return evalImpl(rslt, error);
	}

	/** Evaluate a string containing Jsonnet code, return a JSON string.
	 *
	 * The returned string should be cleaned up with jsonnet_realloc.
	 *
	 * \param filename Path to a file (used in error messages).
	 * \param snippet Jsonnet code to execute.
	 * \param error Return by reference whether or not there was an error.
	 * \returns Either JSON or the error message.
	 */
	JsonnetResult evaluateSnippet(string filename, string snippet) {
		int error;
		char* rslt = jsonnet_evaluate_snippet(this.vm, toStringz(filename),
				toStringz(snippet), &error);
		return evalImpl(rslt, error);
	}

	JsonnetResult evalImpl(char* rslt, int error) {
		scope(exit) {
			jsonnet_realloc(this.vm, rslt, 0);
		}
		JsonnetResult ret;
		if(error) {
			ret.error = fromStringz(rslt).idup;
		} else {
			ret.rslt = nullable(fromStringz(rslt).idup);
		}
		return ret;
	}

	///
	struct JsonnetInterleafedResult {
		string filename;
		JsonnetResult json;
	}

	/** Evaluate a file containing Jsonnet code, return a number of named JSON files.
	 *
	 * The returned character buffer contains an even number of strings, the filename and JSON for each
	 * JSON file interleaved.  It should be cleaned up with jsonnet_realloc.
	 *
	 * \param filename Path to a file containing Jsonnet code.
	 * \param error Return by reference whether or not there was an error.
	 * \returns Either the error, or a sequence of strings separated by \0, terminated with \0\0.
	 */
	JsonnetInterleafedResult[] evaluteFileMulti(string filename) {
		int error;
		char* rslt = jsonnet_evaluate_file_multi(this.vm, toStringz(filename),
				&error);
		return evalImplMulti(rslt, error);
	}

	JsonnetInterleafedResult[] evalImplMulti(char* rslt, int error) {
		import std.array : array;
		import std.algorithm : startsWith;
		import std.exception : assumeUnique, enforce;
		import std.regex : regex, splitter, isRegexFor, Regex;
		import std.range : evenChunks, ElementEncodingType;
		import std.typecons : Yes;
		import std.traits : Unqual;

		scope(exit) {
			jsonnet_realloc(this.vm, rslt, 0);
		}

		JsonnetInterleafedResult[] ret;
		if(error) {
			JsonnetResult e;
			e.error = fromStringz(rslt).idup;
			JsonnetInterleafedResult t;
			t.json = e;
			ret ~= t;
		} else {
			size_t[2] s;
			int idx;
			for(size_t i = 0; !rslt[i .. i + 2].startsWith("\0\0"); ++i) {
				if(rslt[i] == '\0') {
					if(idx == 0) {
						s[1] = i + 1;
					} else if(idx == 1) {
						JsonnetResult e;
						e.rslt = nullable(rslt[s[1] .. i].idup);
						JsonnetInterleafedResult t;
						t.json = e;
						t.filename = rslt[s[0] .. s[1]].idup;
						ret ~= t;

						s[0] = i + 1;
					}
					idx = (idx + 1) % 2;
				}
			}
		}
		return ret;
	}

	/** Evaluate a string containing Jsonnet code, return a number of named JSON files.
	 *
	 * The returned character buffer contains an even number of strings, the filename and JSON for each
	 * JSON file interleaved.  It should be cleaned up with jsonnet_realloc.
	 *
	 * \param filename Path to a file containing Jsonnet code.
	 * \param snippet Jsonnet code to execute.
	 * \param error Return by reference whether or not there was an error.
	 * \returns Either the error, or a sequence of strings separated by \0, terminated with \0\0.
	 */
	JsonnetInterleafedResult[] evaluteSnippetMulti(string filename,
			string snippet)
	{
		int error;
		char* rslt = jsonnet_evaluate_snippet_multi(this.vm, toStringz(filename),
				toStringz(snippet), &error);
		return evalImplMulti(rslt, error);
	}

	/** Evaluate a file containing Jsonnet code, return a number of JSON files.
	 *
	 * The returned character buffer contains several strings.  It should be cleaned up with
	 * jsonnet_realloc.
	 *
	 * \param filename Path to a file containing Jsonnet code.
	 * \param error Return by reference whether or not there was an error.
	 * \returns Either the error, or a sequence of strings separated by \0, terminated with \0\0.
	 */
	JsonnetResult evaluateFileString(string filename) {
		int error;
		char* rslt = jsonnet_evaluate_file_stream(this.vm, toStringz(filename),
				&error);
		return evalImpl(rslt, error);
	}

	/** Evaluate a string containing Jsonnet code, return a number of JSON files.
	 *
	 * The returned character buffer contains several strings.  It should be cleaned up with
	 * jsonnet_realloc.
	 *
	 * \param filename Path to a file containing Jsonnet code.
	 * \param snippet Jsonnet code to execute.
	 * \param error Return by reference whether or not there was an error.
	 * \returns Either the error, or a sequence of strings separated by \0, terminated with \0\0.
	 */
	JsonnetInterleafedResult[] evaluateSnippetStream(string filename,
			string snippet)
	{
		int error;
		char* rslt = jsonnet_evaluate_snippet_stream(this.vm,
				toStringz(filename), toStringz(snippet), &error);
		return evalImplMulti(rslt, error);
	}
}

unittest {
	JsonneD jn = JsonneD();
}
