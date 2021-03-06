print("/// Autogenerated by make_box_builder.py.")
print("extension BoxBuilder {")

blocksCount = 20

for i in range(1, blocksCount):
    print(f"    // buildBlock for {i} child view(s).")
    views = [f"v{vi}" for vi in range(0, i)]
    print(f"    public static func buildBlock<View>({', '.join([f'_ {view}: View' for view in views])}) -> [View] {{")
    print(f"        return [{', '.join(views)}]")
    print("    }")

    if i != blocksCount - 1:
        print("")  # just for the newline

print("}")
