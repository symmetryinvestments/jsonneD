module jsonned.binding;


        import core.stdc.config;
        import core.stdc.stdarg: va_list;
        static import core.simd;
        static import std.conv;

        struct Int128 { long lower; long upper; }
        struct UInt128 { ulong lower; ulong upper; }

        struct __locale_data { int dummy; }



alias _Bool = bool;
struct dpp {
    static struct Opaque(int N) {
        void[N] bytes;
    }

    static bool isEmpty(T)() {
        return T.tupleof.length == 0;
    }
    static struct Move(T) {
        T* ptr;
    }


    static auto move(T)(ref T value) {
        return Move!T(&value);
    }
    mixin template EnumD(string name, T, string prefix) if(is(T == enum)) {
        private static string _memberMixinStr(string member) {
            import std.conv: text;
            import std.array: replace;
            return text(` `, member.replace(prefix, ""), ` = `, T.stringof, `.`, member, `,`);
        }
        private static string _enumMixinStr() {
            import std.array: join;
            string[] ret;
            ret ~= "enum " ~ name ~ "{";
            static foreach(member; __traits(allMembers, T)) {
                ret ~= _memberMixinStr(member);
            }
            ret ~= "}";
            return ret.join("\n");
        }
        mixin(_enumMixinStr());
    }
}

extern(C)
{
    alias wchar_t = int;
    alias size_t = c_ulong;
    alias ptrdiff_t = c_long;
    struct max_align_t
    {
        long __clang_max_align_nonce1;
        real __clang_max_align_nonce2;
    }
    void jsonnet_destroy(JsonnetVm*) @nogc nothrow;
    char* jsonnet_evaluate_snippet_stream(JsonnetVm*, const(char)*, const(char)*, int*) @nogc nothrow;
    char* jsonnet_evaluate_file_stream(JsonnetVm*, const(char)*, int*) @nogc nothrow;
    char* jsonnet_evaluate_snippet_multi(JsonnetVm*, const(char)*, const(char)*, int*) @nogc nothrow;
    char* jsonnet_evaluate_file_multi(JsonnetVm*, const(char)*, int*) @nogc nothrow;
    char* jsonnet_evaluate_snippet(JsonnetVm*, const(char)*, const(char)*, int*) @nogc nothrow;
    char* jsonnet_evaluate_file(JsonnetVm*, const(char)*, int*) @nogc nothrow;
    void jsonnet_jpath_add(JsonnetVm*, const(char)*) @nogc nothrow;
    void jsonnet_max_trace(JsonnetVm*, uint) @nogc nothrow;
    void jsonnet_tla_code(JsonnetVm*, const(char)*, const(char)*) @nogc nothrow;
    void jsonnet_tla_var(JsonnetVm*, const(char)*, const(char)*) @nogc nothrow;
    void jsonnet_ext_code(JsonnetVm*, const(char)*, const(char)*) @nogc nothrow;
    void jsonnet_ext_var(JsonnetVm*, const(char)*, const(char)*) @nogc nothrow;
    void jsonnet_native_callback(JsonnetVm*, const(char)*, JsonnetJsonValue* function(void*, const(const(JsonnetJsonValue)*)*, int*), void*, const(const(char)*)*) @nogc nothrow;
    void jsonnet_import_callback(JsonnetVm*, char* function(void*, const(char)*, const(char)*, char**, int*), void*) @nogc nothrow;
    char* jsonnet_realloc(JsonnetVm*, char*, c_ulong) @nogc nothrow;
    alias JsonnetNativeCallback = JsonnetJsonValue* function(void*, const(const(JsonnetJsonValue)*)*, int*);
    void jsonnet_json_destroy(JsonnetVm*, JsonnetJsonValue*) @nogc nothrow;
    void jsonnet_json_object_append(JsonnetVm*, JsonnetJsonValue*, const(char)*, JsonnetJsonValue*) @nogc nothrow;
    JsonnetJsonValue* jsonnet_json_make_object(JsonnetVm*) @nogc nothrow;
    void jsonnet_json_array_append(JsonnetVm*, JsonnetJsonValue*, JsonnetJsonValue*) @nogc nothrow;
    JsonnetJsonValue* jsonnet_json_make_array(JsonnetVm*) @nogc nothrow;
    JsonnetJsonValue* jsonnet_json_make_null(JsonnetVm*) @nogc nothrow;
    JsonnetJsonValue* jsonnet_json_make_bool(JsonnetVm*, int) @nogc nothrow;
    JsonnetJsonValue* jsonnet_json_make_number(JsonnetVm*, double) @nogc nothrow;
    JsonnetJsonValue* jsonnet_json_make_string(JsonnetVm*, const(char)*) @nogc nothrow;
    int jsonnet_json_extract_null(JsonnetVm*, const(JsonnetJsonValue)*) @nogc nothrow;
    int jsonnet_json_extract_bool(JsonnetVm*, const(JsonnetJsonValue)*) @nogc nothrow;
    int jsonnet_json_extract_number(JsonnetVm*, const(JsonnetJsonValue)*, double*) @nogc nothrow;
    const(char)* jsonnet_json_extract_string(JsonnetVm*, const(JsonnetJsonValue)*) @nogc nothrow;
    struct JsonnetJsonValue;
    alias JsonnetImportCallback = char* function(void*, const(char)*, const(char)*, char**, int*);
    void jsonnet_string_output(JsonnetVm*, int) @nogc nothrow;
    void jsonnet_gc_growth_trigger(JsonnetVm*, double) @nogc nothrow;
    void jsonnet_gc_min_objects(JsonnetVm*, uint) @nogc nothrow;
    void jsonnet_max_stack(JsonnetVm*, uint) @nogc nothrow;
    JsonnetVm* jsonnet_make() @nogc nothrow;
    struct JsonnetVm;
    const(char)* jsonnet_version() @nogc nothrow;






    static if(!is(typeof(LIB_JSONNET_VERSION))) {
        enum LIB_JSONNET_VERSION = "v0.14.0";
    }
}
