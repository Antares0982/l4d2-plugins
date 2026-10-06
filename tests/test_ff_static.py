"""Run with python3 tests/test_ff_static.py; requires c++."""

from pathlib import Path
import re
import subprocess
import tempfile


source = (Path(__file__).resolve().parents[1] / "ff_static.sp").read_text()
data = re.search(r"enum struct FFdata\n\{.*?\n\}", source, re.S).group()
ranking = re.search(
    r"int determine_most_friendlyfire\(FFdata\[\] dataarray\)\n\{.*?\n\}",
    source,
    re.S,
).group()
# Execute the original comparison as C++.
program = (
    """
#include <cassert>
#include <tuple>
constexpr int MAXPLAYERS = 3;
bool active[MAXPLAYERS + 1];
bool is_client_actual(int client) { return active[client]; }
"""
    + data.replace("enum struct", "struct")
    + ";\n"
    + ranking.replace("FFdata[] dataarray", "FFdata dataarray[]")
    + """
int main()
{
    const int values[] = {0, 1, 10000};
    FFdata cases[27];
    int count = 0;
    for (int kills : values)
        for (int incaps : values)
            for (int damage : values)
                cases[count++] = {damage, incaps, kills};
    for (const auto &a : cases)
        for (const auto &b : cases)
            for (int mask = 0; mask < 8; ++mask)
            {
                FFdata rows[MAXPLAYERS + 1] = {{}, a, b, a};
                std::tuple<int, int, int> best{0, 0, 0};
                int expected = 0;
                for (int i = 1; i <= MAXPLAYERS; ++i)
                {
                    active[i] = mask & (1 << (i - 1));
                    auto key = std::make_tuple(rows[i].killFriend,
                        rows[i].incapFriend, rows[i].totalFriendlyFire);
                    if (active[i] && key > best)
                    {
                        best = key;
                        expected = i;
                    }
                }
                assert(determine_most_friendlyfire(rows) == expected);
            }
}
"""
)
with tempfile.TemporaryDirectory() as directory:
    binary = str(Path(directory) / "ff-static")
    subprocess.run(
        ["c++", "-std=c++11", "-x", "c++", "-", "-o", binary],
        input=program,
        text=True,
        check=True,
    )
    subprocess.run([binary], check=True)
print("Friendly fire ranking: 5832 cases passed")
