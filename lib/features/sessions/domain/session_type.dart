enum SessionType {
  doorToDoor('Door to Door Cold Calling'),
  flyerRun('Flyer Run'),
  nowHiringFlyers('Now Hiring Flyers'),
  other('Other / Misc');

  final String label;
  const SessionType(this.label);
}