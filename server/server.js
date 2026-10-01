========================================================= */
app.get('/test-batch/student/:rollNo', async (req, res) => {
	const rollNo = String(req.params.rollNo || '').toUpperCase().trim();
	if (!/^IAT[0-9]{3,}$/.test(rollNo)) {
		return res.status(400).json({ error: 'Invalid Test Batch roll number' });
	}
	try {
		const result = await pool.query(
			`SELECT s.roll_no, s.name, s.class, s.board, s.mode_of_education,
					s.phone, s.email, s.school_name, s.test_series_id,
					ts.name AS test_series_name
			 FROM test_batch_students s
			 JOIN test_series ts ON ts.id = s.test_series_id
			 WHERE s.roll_no = $1`,
			[rollNo]
		);
		if (result.rows.length === 0) {
			return res.status(404).json({ error: 'Test Batch student not found' });
		}
		res.json({ student: result.rows[0] });
	} catch (err) {
		console.error('GET /test-batch/student/:rollNo error:', err);
		res.status(500).json({ error: 'Failed to load Test Batch student' });
	}
});
