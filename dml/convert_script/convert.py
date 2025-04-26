tables = dict()
table = None

insert_string = "INSERT ALL\n"


with open("./data.txt", "r") as f:
    for line in f.readlines():
        s_line = line.strip()
        if s_line.startswith("-"):
            table = s_line[1:]
            tables[table] = []
        else:
            tables[table].append(s_line)

    for table, inserts in tables.items():
        for insert in inserts:
            insert_string += "INTO " + table + " VALUES(" + insert + ")\n"

    print(insert_string)