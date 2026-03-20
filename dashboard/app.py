from flask import Flask, render_template, request, redirect, url_for, flash
import mysql.connector
from datetime import datetime

app = Flask(__name__, static_folder='static', static_url_path='/static')
app.secret_key = 'your_secret_key_123'

# Database Connection
def get_db_connection():
    conn = mysql.connector.connect(
        host="localhost",
        user="root",
        password="root",  # ⚠️ CHANGE THIS to your MySQL password
        database="incident_tracker"
    )
    return conn

@app.route('/')
def dashboard():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM IncidentSummaryView")
    summary = cursor.fetchone()
    
    cursor.execute("SELECT * FROM ActiveIncidentsView LIMIT 20")
    incidents = cursor.fetchall()
    
    cursor.execute("""
        SELECT u.username, COUNT(i.incident_id) as total_incidents,
               SUM(CASE WHEN i.status = 'resolved' THEN 1 ELSE 0 END) as resolved
        FROM Users u
        LEFT JOIN Incidents i ON u.user_id = i.assigned_to
        GROUP BY u.user_id
    """)
    analysts = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('index.html', 
                         summary=summary, 
                         incidents=incidents,
                         analysts=analysts,
                         now=datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

@app.route('/incident/<int:incident_id>')
def view_incident(incident_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("""
        SELECT i.*, c.name as category_name, a.asset_name, a.ip_address,
               u1.username as reported_by_name, u2.username as assigned_to_name
        FROM Incidents i
        LEFT JOIN Categories c ON i.category_id = c.category_id
        LEFT JOIN Assets a ON i.asset_id = a.asset_id
        LEFT JOIN Users u1 ON i.reported_by = u1.user_id
        LEFT JOIN Users u2 ON i.assigned_to = u2.user_id
        WHERE i.incident_id = %s
    """, (incident_id,))
    incident = cursor.fetchone()
    
    cursor.execute("""
        SELECT a.*, u.username as performed_by_name
        FROM Actions a
        JOIN Users u ON a.performed_by = u.user_id
        WHERE a.incident_id = %s
        ORDER BY a.performed_at DESC
    """, (incident_id,))
    actions = cursor.fetchall()
    
    cursor.execute("SELECT user_id, username FROM Users WHERE role IN ('analyst', 'admin') AND is_active = TRUE")
    analysts = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('view_incident.html', 
                         incident=incident, 
                         actions=actions,
                         analysts=analysts)

@app.route('/incident/add', methods=['GET', 'POST'])
def add_incident():
    if request.method == 'POST':
        title = request.form['title']
        description = request.form['description']
        category_id = request.form['category_id']
        severity = request.form['severity']
        priority = request.form['priority']
        asset_id = request.form['asset_id']
        reported_by = request.form['reported_by']
        assigned_to = request.form.get('assigned_to') or None
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO Incidents (title, description, category_id, severity, status, priority, 
                                   reported_by, assigned_to, asset_id)
            VALUES (%s, %s, %s, %s, 'reported', %s, %s, %s, %s)
        """, (title, description, category_id, severity, priority, reported_by, assigned_to, asset_id))
        
        incident_id = cursor.lastrowid
        conn.commit()
        cursor.close()
        conn.close()
        
        flash(f'Incident #{incident_id} created successfully!', 'success')
        return redirect(url_for('view_incident', incident_id=incident_id))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT category_id, name FROM Categories")
    categories = cursor.fetchall()
    cursor.execute("SELECT asset_id, asset_name, ip_address FROM Assets")
    assets = cursor.fetchall()
    cursor.execute("SELECT user_id, username FROM Users WHERE is_active = TRUE")
    users = cursor.fetchall()
    cursor.execute("SELECT user_id, username FROM Users WHERE role = 'analyst' AND is_active = TRUE")
    analysts = cursor.fetchall()
    cursor.close()
    conn.close()
    
    return render_template('add_incident.html', 
                         categories=categories, 
                         assets=assets, 
                         users=users,
                         analysts=analysts)

@app.route('/incident/<int:incident_id>/edit', methods=['GET', 'POST'])
def edit_incident(incident_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    if request.method == 'POST':
        title = request.form['title']
        description = request.form['description']
        category_id = request.form['category_id']
        severity = request.form['severity']
        priority = request.form['priority']
        asset_id = request.form['asset_id']
        status = request.form['status']
        assigned_to = request.form.get('assigned_to') or None
        
        cursor.execute("""
            UPDATE Incidents 
            SET title=%s, description=%s, category_id=%s, severity=%s, 
                priority=%s, asset_id=%s, status=%s, assigned_to=%s
            WHERE incident_id=%s
        """, (title, description, category_id, severity, priority, asset_id, status, assigned_to, incident_id))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        flash(f'Incident #{incident_id} updated successfully!', 'success')
        return redirect(url_for('view_incident', incident_id=incident_id))
    
    cursor.execute("SELECT * FROM Incidents WHERE incident_id = %s", (incident_id,))
    incident = cursor.fetchone()
    
    cursor.execute("SELECT category_id, name FROM Categories")
    categories = cursor.fetchall()
    cursor.execute("SELECT asset_id, asset_name, ip_address FROM Assets")
    assets = cursor.fetchall()
    cursor.execute("SELECT user_id, username FROM Users WHERE is_active = TRUE")
    users = cursor.fetchall()
    cursor.execute("SELECT user_id, username FROM Users WHERE role = 'analyst' AND is_active = TRUE")
    analysts = cursor.fetchall()
    cursor.close()
    conn.close()
    
    return render_template('edit_incident.html', 
                         incident=incident,
                         categories=categories, 
                         assets=assets, 
                         users=users,
                         analysts=analysts)

@app.route('/incident/<int:incident_id>/delete', methods=['POST'])
def delete_incident(incident_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("DELETE FROM Actions WHERE incident_id = %s", (incident_id,))
        cursor.execute("DELETE FROM Evidence WHERE incident_id = %s", (incident_id,))
        cursor.execute("DELETE FROM Incidents WHERE incident_id = %s", (incident_id,))
        conn.commit()
        flash(f'Incident #{incident_id} deleted successfully!', 'success')
    except Exception as e:
        flash(f'Error deleting incident: {str(e)}', 'error')
    finally:
        cursor.close()
        conn.close()
    
    return redirect(url_for('dashboard'))

@app.route('/incident/<int:incident_id>/update_status', methods=['POST'])
def update_status(incident_id):
    new_status = request.form['status']
    analyst_id = request.form.get('analyst_id') or None
    notes = request.form.get('notes', '')
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    if new_status == 'resolved':
        cursor.execute("""
            UPDATE Incidents 
            SET status = %s, resolved_at = NOW(), assigned_to = COALESCE(%s, assigned_to)
            WHERE incident_id = %s
        """, (new_status, analyst_id, incident_id))
    else:
        cursor.execute("""
            UPDATE Incidents 
            SET status = %s, assigned_to = COALESCE(%s, assigned_to)
            WHERE incident_id = %s
        """, (new_status, analyst_id, incident_id))
    
    if notes:
        cursor.execute("""
            INSERT INTO Actions (incident_id, action_type, action_description, performed_by)
            VALUES (%s, 'documentation', %s, %s)
        """, (incident_id, f'Status changed to {new_status}. {notes}', analyst_id or 1))
    
    conn.commit()
    cursor.close()
    conn.close()
    
    flash(f'Incident #{incident_id} updated!', 'success')
    return redirect(url_for('view_incident', incident_id=incident_id))

@app.route('/incident/<int:incident_id>/add_action', methods=['POST'])
def add_action(incident_id):
    action_type = request.form['action_type']
    description = request.form['description']
    performed_by = request.form['performed_by']
    time_spent = request.form.get('time_spent', 0)
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("""
        INSERT INTO Actions (incident_id, action_type, action_description, performed_by, time_spent_minutes)
        VALUES (%s, %s, %s, %s, %s)
    """, (incident_id, action_type, description, performed_by, time_spent))
    
    conn.commit()
    cursor.close()
    conn.close()
    
    flash('Action added successfully!', 'success')
    return redirect(url_for('view_incident', incident_id=incident_id))

@app.route('/incident/<int:incident_id>/assign', methods=['POST'])
def assign_incident(incident_id):
    analyst_id = request.form['analyst_id']
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("""
        UPDATE Incidents 
        SET assigned_to = %s, status = 'investigating'
        WHERE incident_id = %s
    """, (analyst_id, incident_id))
    
    cursor.execute("""
        INSERT INTO Actions (incident_id, action_type, action_description, performed_by)
        VALUES (%s, 'communication', %s, %s)
    """, (incident_id, f'Assigned to analyst ID {analyst_id}', analyst_id))
    
    conn.commit()
    cursor.close()
    conn.close()
    
    flash(f'Incident #{incident_id} assigned successfully!', 'success')
    return redirect(url_for('view_incident', incident_id=incident_id))

if __name__ == '__main__':
    app.run(debug=True)