"""Apply views_mysql.sql (the 5 views + sp_make_booking) to an EXISTING
database WITHOUT reseeding it. Use this after pulling a version that adds
DB-side objects, when you don't want to rebuild the demo data:
    python flask_app/apply_views.py [dbname]     (default: skyroute_app)
Needs MySQL running + python/flask_app/.env credentials."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from db import connect  # noqa: E402

ROOT = Path(__file__).resolve().parent
DBNAME = sys.argv[1] if len(sys.argv) > 1 else "skyroute_app"


def main(dbname=DBNAME):
    sql = (ROOT / "views_mysql.sql").read_text(encoding="utf-8")
    blocks = [b.strip() for b in sql.split("-- @@") if b.strip()]
    con = connect(dbname)
    try:
        cur = con.cursor()
        for block in blocks:
            cur.execute(block)
        con.commit()
        cur.execute(
            "SELECT TABLE_NAME FROM information_schema.VIEWS "
            "WHERE TABLE_SCHEMA = %s ORDER BY TABLE_NAME", (dbname,))
        views = [r[0] for r in cur.fetchall()]
        cur.execute(
            "SELECT ROUTINE_NAME FROM information_schema.ROUTINES "
            "WHERE ROUTINE_SCHEMA = %s ORDER BY ROUTINE_NAME", (dbname,))
        procs = [r[0] for r in cur.fetchall()]
        cur.execute("SELECT COUNT(*) FROM v_departure_board")
        board = cur.fetchone()[0]
        print(f"{dbname}: views={views} procedures={procs} "
              f"v_departure_board_rows={board}")
    finally:
        con.close()


if __name__ == "__main__":
    main()
