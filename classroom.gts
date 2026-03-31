import {
  CardDef,
  field,
  contains,
  linksTo,
  linksToMany,
  Component,
  getCards,
} from 'https://cardstack.com/base/card-api';
import StringField from 'https://cardstack.com/base/string';
import DateField from 'https://cardstack.com/base/date';
import SchoolIcon from '@cardstack/boxel-icons/school';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { eq } from '@cardstack/boxel-ui/helpers';
import { formatDateTime } from '@cardstack/boxel-ui/helpers';
import { Staff } from './staff';
import { Student } from './student';

export class Classroom extends CardDef {
  static displayName = 'Classroom';
  static icon = SchoolIcon;
  static prefersWideFormat = true;

  @field classroomName = contains(StringField);
  @field teacher = linksTo(Staff);
  @field students = linksToMany(Student);
  @field date = contains(DateField);

  @field title = contains(StringField, {
    computeVia: function (this: Classroom) {
      return this.classroomName ?? 'Untitled Classroom';
    },
  });

  static isolated = class Isolated extends Component<typeof Classroom> {
    @tracked selectedStudentIndex = 0;
    @tracked activityEntries: any[] = [];
    @tracked learningGoals: any[] = [];
    @tracked isLoading = true;
    @tracked noteContent = '';
    @tracked localEntries: any[] = [];
    @tracked selectedEntryType = 'Academic';

    constructor(owner: any, args: any) {
      super(owner, args);
      this.loadData();
    }

    async loadData() {
      try {
        this.isLoading = true;
        const realmURL = this.args.model?.[Symbol.for('realmURL')];
        const [entries, goals] = await Promise.all([
          getCards({ filter: { type: { module: new URL('./activity-entry', import.meta.url).href, name: 'ActivityEntry' } } }, { realmURL }),
          getCards({ filter: { type: { module: new URL('./learning-goal', import.meta.url).href, name: 'LearningGoal' } } }, { realmURL }),
        ]);
        this.activityEntries = entries || [];
        this.learningGoals = goals || [];
      } catch (error) {
        console.error('Error loading dashboard data:', error);
      } finally {
        this.isLoading = false;
      }
    }

    get allStudents() { return this.args.model?.students ?? []; }
    get inClassroom() { return this.allStudents.filter((s: any) => s.location === 'In Classroom'); }
    get atSpecialists() { return this.allStudents.filter((s: any) => s.location === 'At Specialists'); }
    get absent() { return this.allStudents.filter((s: any) => s.location === 'Absent'); }
    get presentCount() { return this.inClassroom.length + this.atSpecialists.length; }
    get totalCount() { return this.allStudents.length; }

    get selectedStudent() { return this.allStudents[this.selectedStudentIndex] ?? null; }
    get selectedStudentId() { return this.selectedStudent?.id ?? null; }

    get studentGoals() {
      if (!this.selectedStudentId) return [];
      return this.learningGoals.filter((g: any) => g.student?.id === this.selectedStudentId);
    }

    get studentEntries() {
      if (!this.selectedStudentId) return [];
      const fetched = this.activityEntries
        .filter((e: any) => e.student?.id === this.selectedStudentId);
      const local = this.localEntries
        .filter((e: any) => e.student?.id === this.selectedStudentId);
      return [...local, ...fetched]
        .sort((a: any, b: any) => {
          const ta = a.timestamp ? new Date(a.timestamp).getTime() : 0;
          const tb = b.timestamp ? new Date(b.timestamp).getTime() : 0;
          return tb - ta;
        });
    }

    get hudAlerts() {
      const alerts: any[] = [];
      for (const student of this.allStudents) {
        if (student.alerts) {
          for (const alert of student.alerts) {
            if (alert.urgency === 'Urgent') {
              alerts.push({ studentName: student.shortName ?? student.name, ...alert });
            }
          }
        }
      }
      return alerts;
    }

    get teacherName() { return this.args.model?.teacher?.name ?? 'Teacher'; }
    get teacherInitials() { return this.args.model?.teacher?.initials ?? ''; }
    get classLabel() { return this.args.model?.classroomName ?? 'Classroom'; }

    get todayFormatted() {
      const d = new Date();
      const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return `${days[d.getDay()]}, ${months[d.getMonth()]} ${d.getDate()}`;
    }

    @action selectStudent(index: number) {
      this.selectedStudentIndex = index;
      this.noteContent = '';
      if (this.textareaEl) this.textareaEl.value = '';
    }

    @action selectStudentByObj(student: any) {
      const idx = this.allStudents.indexOf(student);
      this.selectedStudentIndex = idx >= 0 ? idx : 0;
      this.noteContent = '';
      if (this.textareaEl) this.textareaEl.value = '';
    }

    isSelectedStudent(student: any) {
      return this.allStudents.indexOf(student) === this.selectedStudentIndex;
    }

    private textareaEl: HTMLTextAreaElement | null = null;

    @action updateNote(event: Event) {
      this.textareaEl = event.target as HTMLTextAreaElement;
      this.noteContent = this.textareaEl.value;
    }

    @action postNote() {
      if (!this.noteContent.trim() || !this.selectedStudent) return;
      const entry = {
        content: this.noteContent,
        entryType: this.selectedEntryType,
        author: { name: this.teacherName, initials: this.teacherInitials, color: 'teal' },
        student: this.selectedStudent,
        timestamp: new Date().toISOString(),
        aiTagged: 'false',
        isLocal: true,
      };
      this.localEntries = [entry, ...this.localEntries];
      this.noteContent = '';
      if (this.textareaEl) this.textareaEl.value = '';
    }

    @action setEntryType(type: string) {
      this.selectedEntryType = type;
    }

    isSelected(student: any) {
      return this.allStudents.indexOf(student) === this.selectedStudentIndex;
    }

    getStudentIndex(student: any) {
      return this.allStudents.indexOf(student);
    }

    getStaffColorClass(color: string) {
      if (color === 'teal') return 'teal';
      if (color === 'purple') return 'purple';
      if (color === 'coral') return 'coral';
      if (color === 'amber') return 'amber';
      return 'teal';
    }

    getDomainColorClass(domain: string) {
      switch (domain) {
        case 'Math': return 'coral';
        case 'Reading': return 'amber';
        case 'Social': return 'purple';
        case 'Behavioral': return 'amber';
        case 'Motor': return 'teal';
        default: return 'teal';
      }
    }

    getEntryTypeClass(type: string) {
      switch (type) {
        case 'Academic': return 'academic';
        case 'Social': return 'social';
        case 'Behavioral': return 'behavioral';
        default: return 'academic';
      }
    }

    <template>
      <div class='hero-frame'>
        {{!-- Frame Bar --}}
        <div class='frame-bar'>
          <span class='frame-title'>{{this.classLabel}} · {{this.teacherName}}</span>
          <span class='frame-time'>{{this.todayFormatted}}</span>
        </div>

        {{!-- HUD Banner --}}
        {{#if this.hudAlerts.length}}
          <div class='hud-banner'>
            {{#each this.hudAlerts as |alert|}}
              <div class='hud-alert {{if (eq alert.alertType "Pickup Change") "urgent"}} {{if (eq alert.alertType "Schedule") "schedule"}} {{if (eq alert.alertType "Sub Alert") "sub"}}'>
                {{#if (eq alert.alertType "Pickup Change")}}
                  <svg width='16' height='16' viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='2'><path d='M8 4v4M8 11v1'/><path d='M3 14h10L8 3 3 14z'/></svg>
                {{else if (eq alert.alertType "Schedule")}}
                  <svg width='16' height='16' viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.5'><circle cx='8' cy='8' r='6'/><path d='M8 5v3.5l2.5 1.5'/></svg>
                {{else}}
                  <svg width='16' height='16' viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.5'><circle cx='8' cy='6' r='3'/><path d='M3 14c0-2.5 2.5-4 5-4s5 1.5 5 4'/></svg>
                {{/if}}
                <span class='hud-text'><strong>{{alert.alertType}}:</strong> {{alert.message}}</span>
                {{#if alert.detail}}
                  <span class='hud-badge'>{{alert.detail}}</span>
                {{/if}}
              </div>
            {{/each}}
          </div>
        {{/if}}

        {{!-- 3-Column Dashboard --}}
        <div class='classroom-dashboard'>

          {{!-- COLUMN 1: Roster --}}
          <div class='cd-roster'>
            <header class='cd-col-header'>
              <h3 class='cd-col-title'>Today's Roster</h3>
              <span class='cd-col-count'>{{this.presentCount}} of {{this.totalCount}} present</span>
            </header>

            {{#if this.inClassroom.length}}
              <div class='roster-section'>
                <div class='roster-label'>
                  <span class='roster-location'>
                    <svg width='10' height='10' viewBox='0 0 10 10' fill='currentColor'><circle cx='5' cy='5' r='4'/></svg>
                    In Classroom
                  </span>
                  <span class='roster-count'>{{this.inClassroom.length}}</span>
                </div>
                {{#each this.inClassroom as |student|}}
                  <div class='roster-student' role='button' {{on "click" (fn this.selectStudentByObj student)}}>
                    <div class='rs-avatar'>
                      {{#if student.avatar}}
                        <img src={{student.avatar}} alt='' />
                      {{/if}}
                      <span class='rs-status present'></span>
                    </div>
                    <div class='rs-info'>
                      <span class='rs-name'>{{if student.shortName student.shortName "Student"}}</span>
                      <div class='rs-tags'>
                        {{#each student.tags as |tag|}}
                          <span class='rs-tag {{if (eq tag "IEP") "iep"}} {{if (eq tag "Allergy") "allergy"}} {{if (eq tag "504") "plan"}}'>{{tag}}</span>
                        {{/each}}
                      </div>
                    </div>
                  </div>
                {{/each}}
              </div>
            {{/if}}

            {{#if this.atSpecialists.length}}
              <div class='roster-section'>
                <div class='roster-label'>
                  <span class='roster-location away'>
                    <svg width='10' height='10' viewBox='0 0 10 10' fill='none' stroke='currentColor' stroke-width='1.5'><path d='M2 5h6M5 2l3 3-3 3'/></svg>
                    At Specialists
                  </span>
                  <span class='roster-count'>{{this.atSpecialists.length}}</span>
                </div>
                {{#each this.atSpecialists as |student|}}
                  <div class='roster-student away' role='button' {{on "click" (fn this.selectStudentByObj student)}}>
                    <div class='rs-avatar'>
                      {{#if student.avatar}}
                        <img src={{student.avatar}} alt='' />
                      {{/if}}
                      <span class='rs-status away'></span>
                    </div>
                    <div class='rs-info'>
                      <span class='rs-name'>{{if student.shortName student.shortName "Student"}}</span>
                      <span class='rs-location'>{{student.locationDetail}}</span>
                      {{#if student.returnTime}}
                        <span class='rs-return'>{{student.returnTime}}</span>
                      {{/if}}
                    </div>
                  </div>
                {{/each}}
              </div>
            {{/if}}

            {{#if this.absent.length}}
              <div class='roster-section'>
                <div class='roster-label'>
                  <span class='roster-location absent'>
                    <svg width='10' height='10' viewBox='0 0 10 10' fill='none' stroke='currentColor' stroke-width='1.5'><path d='M2 2l6 6M8 2l-6 6'/></svg>
                    Absent
                  </span>
                  <span class='roster-count'>{{this.absent.length}}</span>
                </div>
                {{#each this.absent as |student|}}
                  <div class='roster-student absent-row' role='button' {{on "click" (fn this.selectStudentByObj student)}}>
                    <div class='rs-avatar'>
                      {{#if student.avatar}}
                        <img src={{student.avatar}} alt='' />
                      {{/if}}
                      <span class='rs-status absent'></span>
                    </div>
                    <div class='rs-info'>
                      <span class='rs-name'>{{if student.shortName student.shortName "Student"}}</span>
                      <span class='rs-reason'>{{student.locationDetail}}</span>
                    </div>
                  </div>
                {{/each}}
              </div>
            {{/if}}
          </div>

          {{!-- COLUMN 2: Student Detail --}}
          <div class='cd-daily'>
            {{#if this.selectedStudent}}
              <header class='cd-student-header'>
                <div class='cd-student-id'>
                  <div class='cd-student-avatar'>
                    <img src={{this.selectedStudent.avatar}} alt={{this.selectedStudent.name}} />
                  </div>
                  <div class='cd-student-info'>
                    <h2 class='cd-student-name'>{{this.selectedStudent.name}}</h2>
                    <span class='cd-student-meta'>
                      {{this.selectedStudent.grade}}
                      {{#if this.selectedStudent.age}}
                        · Age {{this.selectedStudent.age}}
                      {{/if}}
                    </span>
                    <div class='cd-student-tags'>
                      {{#each this.selectedStudent.tags as |tag|}}
                        <span class='cd-tag {{if (eq tag "IEP") "iep"}} {{if (eq tag "Allergy") "allergy"}} {{if (eq tag "504") "plan"}}'>{{tag}}</span>
                      {{/each}}
                    </div>
                  </div>
                </div>
                {{#if this.selectedStudent.supportStaff}}
                  <div class='cd-student-staff'>
                    <span class='cd-staff-label'>Working with</span>
                    <div class='cd-staff-assigned'>
                      <span class='staff-avatar-sm {{this.getStaffColorClass this.selectedStudent.supportStaff.color}}'>{{this.selectedStudent.supportStaff.initials}}</span>
                      <span class='cd-staff-name'>{{this.selectedStudent.supportStaff.name}}</span>
                    </div>
                  </div>
                {{/if}}
              </header>

              {{!-- Alerts --}}
              {{#if this.selectedStudent.alerts.length}}
                <div class='cd-alerts'>
                  {{#each this.selectedStudent.alerts as |alert|}}
                    <div class='cd-alert {{if (eq alert.urgency "Urgent") "urgent" "note"}}'>
                      {{#if (eq alert.urgency "Urgent")}}
                        <svg width='14' height='14' viewBox='0 0 14 14' fill='none' stroke='currentColor' stroke-width='1.5'><path d='M7 4v3M7 9v.5'/><path d='M3 12h8L7 3 3 12z'/></svg>
                      {{else}}
                        <svg width='14' height='14' viewBox='0 0 14 14' fill='none' stroke='currentColor' stroke-width='1.5'><circle cx='7' cy='7' r='5.5'/><path d='M7 5v3'/><circle cx='7' cy='10' r='0.5' fill='currentColor'/></svg>
                      {{/if}}
                      <div class='cd-alert-content'>
                        <span class='cd-alert-title'>{{alert.alertType}}</span>
                        <span class='cd-alert-text'>{{alert.message}}{{#if alert.detail}} ({{alert.detail}}){{/if}}</span>
                      </div>
                    </div>
                  {{/each}}
                </div>
              {{/if}}

              {{!-- Schedule --}}
              {{#if this.selectedStudent.schedule.length}}
                <div class='cd-plan'>
                  <h4 class='cd-section-title'>Today's Plan</h4>
                  <div class='cd-schedule'>
                    {{#each this.selectedStudent.schedule as |item|}}
                      <div class='cd-sched-item {{if (eq item.status "Done") "done"}} {{if (eq item.status "Current") "current"}}'>
                        <span class='cd-sched-time'>{{item.time}}</span>
                        <span class='cd-sched-dot'></span>
                        <div class='cd-sched-content'>
                          <span class='cd-sched-activity'>{{item.activity}}</span>
                          {{#if item.result}}
                            <span class='cd-sched-result good'>{{item.result}}</span>
                          {{/if}}
                          {{#if (eq item.status "Current")}}
                            <span class='cd-sched-tag'>Now</span>
                          {{/if}}
                          {{#if item.goalTag}}
                            <span class='cd-sched-tag goal'>{{item.goalTag}}</span>
                          {{/if}}
                        </div>
                      </div>
                    {{/each}}
                  </div>
                </div>
              {{/if}}

              {{!-- Goals --}}
              {{#if this.studentGoals.length}}
                <div class='cd-goals'>
                  <h4 class='cd-section-title'>Active Goals <span class='cd-section-badge'>{{this.studentGoals.length}}</span></h4>
                  <div class='cd-goal-cards'>
                    {{#each this.studentGoals as |goal|}}
                      <div class='cd-goal-card'>
                        <div class='cd-gc-header'>
                          <span class='cd-gc-domain {{this.getDomainColorClass goal.domain}}'>{{goal.domain}}</span>
                          <span class='cd-gc-pct'>{{goal.currentMastery}}%</span>
                        </div>
                        <span class='cd-gc-title'>{{goal.goalTitle}}</span>
                        <div class='cd-gc-track'>
                          <div class='cd-gc-fill' style='width: {{goal.currentMastery}}%'></div>
                        </div>
                      </div>
                    {{/each}}
                  </div>
                </div>
              {{/if}}

            {{else}}
              <div class='empty-state'>Select a student from the roster</div>
            {{/if}}
          </div>

          {{!-- COLUMN 3: Activity Feed --}}
          <div class='cd-feed'>
            {{!-- Quick Entry --}}
            <div class='cd-quick-entry'>
              <div class='qe-input-row'>
                <div class='qe-avatar'>
                  <span class='staff-avatar-sm teal'>{{this.teacherInitials}}</span>
                </div>
                <textarea class='qe-textarea' placeholder='Quick note about {{this.selectedStudent.shortName}}...' {{on "input" this.updateNote}}></textarea>
              </div>
              <div class='qe-type-selector'>
                <button class='type-btn {{if (eq this.selectedEntryType "Academic") "active"}}' type='button' {{on "click" (fn this.setEntryType "Academic")}}>Academic</button>
                <button class='type-btn {{if (eq this.selectedEntryType "Social") "active"}}' type='button' {{on "click" (fn this.setEntryType "Social")}}>Social</button>
                <button class='type-btn {{if (eq this.selectedEntryType "Behavioral") "active"}}' type='button' {{on "click" (fn this.setEntryType "Behavioral")}}>Behavioral</button>
              </div>
              <div class='qe-actions'>
                <div class='qe-attach'>
                  <button class='qe-attach-btn' title='Add photo' type='button'>
                    <svg width='16' height='16' viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.5'><rect x='2' y='3' width='12' height='10' rx='2'/><circle cx='5.5' cy='6.5' r='1.5'/><path d='M2 11l3-3 2 2 4-4 3 3'/></svg>
                  </button>
                  <button class='qe-attach-btn' title='Voice note' type='button'>
                    <svg width='16' height='16' viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.5'><path d='M8 2v8M5 6v4a3 3 0 006 0V6'/><path d='M8 14v1'/></svg>
                  </button>
                </div>
                <button class='qe-submit' type='button' {{on "click" this.postNote}}>
                  <span>Post</span>
                  <svg width='14' height='14' viewBox='0 0 14 14' fill='none' stroke='currentColor' stroke-width='2'><path d='M2 7h10M8 3l4 4-4 4'/></svg>
                </button>
              </div>
              <div class='qe-hint'>
                <svg width='12' height='12' viewBox='0 0 12 12' fill='none' stroke='currentColor' stroke-width='1.5'><circle cx='6' cy='6' r='5'/><path d='M6 4v2'/><circle cx='6' cy='8' r='0.5' fill='currentColor'/></svg>
                <span>AI will tag after you post</span>
              </div>
            </div>

            {{!-- Feed Header --}}
            <header class='cd-feed-header'>
              <h4 class='cd-section-title'>Today's Activity</h4>
              <span class='cd-feed-count'>{{this.studentEntries.length}} entries</span>
            </header>

            {{!-- Feed Entries --}}
            <div class='cd-feed-entries'>
              {{#if this.isLoading}}
                <div class='empty-state'>Loading entries...</div>
              {{else if this.studentEntries.length}}
                {{#each this.studentEntries as |entry|}}
                  <div class='cd-entry {{if (eq entry.aiTagged "true") "ai-processed"}} {{if entry.isLocal "local-entry"}}'>
                    {{#if entry.isLocal}}
                      <div class='cd-entry-local-badge'>Local</div>
                    {{/if}}
                    {{#if (eq entry.aiTagged "true")}}
                      <div class='cd-entry-ai'>
                        <div class='ai-badge'>
                          <svg width='10' height='10' viewBox='0 0 10 10' fill='currentColor'><circle cx='5' cy='5' r='4'/></svg>
                          AI Tagged
                        </div>
                        <div class='ai-suggestion'>
                          <span class='ai-type {{this.getEntryTypeClass entry.entryType}}'>{{entry.entryType}}</span>
                          {{#if entry.goalLink.goalTitle}}
                            <span class='ai-goal'>→ {{entry.goalLink.goalTitle}}</span>
                          {{/if}}
                        </div>
                        <div class='ai-actions'>
                          <button class='ai-accept' type='button'>Accept</button>
                          <button class='ai-edit' type='button'>Edit</button>
                        </div>
                      </div>
                    {{/if}}
                    <div class='cd-entry-content'>
                      <div class='cd-entry-header'>
                        <span class='staff-avatar-mini {{this.getStaffColorClass entry.author.color}}'>{{entry.author.initials}}</span>
                        <span class='cd-entry-author'>{{entry.author.name}}</span>
                        {{#if entry.timestamp}}
                          <span class='cd-entry-time'>{{formatDateTime entry.timestamp 'h:mm A'}}</span>
                        {{/if}}
                      </div>
                      <p class='cd-entry-text'>{{entry.content}}</p>
                      <div class='cd-entry-tags'>
                        <span class='cd-entry-type {{this.getEntryTypeClass entry.entryType}}'>{{entry.entryType}}</span>
                        {{#if entry.goalLink.goalTitle}}
                          <span class='cd-entry-goal'>→ {{entry.goalLink.goalTitle}}</span>
                        {{/if}}
                        {{#if entry.score}}
                          <span class='cd-entry-score good'>{{entry.score}}</span>
                        {{/if}}
                      </div>
                      {{#if entry.flagNote}}
                        <div class='cd-entry-flag'>{{entry.flagNote}}</div>
                      {{/if}}
                    </div>
                  </div>
                {{/each}}
              {{else}}
                <div class='empty-state'>No activity entries yet</div>
              {{/if}}
            </div>
          </div>

        </div>
      </div>

      <style scoped>
        /* ═══ Design Tokens ═══ */
        .hero-frame {
          --surface-0: #fffdfb;
          --surface-1: #faf8f6;
          --surface-2: #f5f2ef;
          --surface-3: #ebe7e3;
          --text-1: #1a1816;
          --text-2: #5c5650;
          --text-3: #8a8279;
          --coral: #e05d50;
          --coral-soft: #fdf0ee;
          --amber: #c08b30;
          --amber-soft: #fdf6e8;
          --purple: #7c5fc4;
          --purple-soft: #f4f0fa;
          --teal: #2a9d8f;
          --teal-soft: #e8f6f4;
          --radius-sm: 6px;
          --radius-md: 10px;
          --radius-lg: 14px;

          display: flex;
          flex-direction: column;
          height: 100%;
          min-height: 700px;
          font-family: 'Inter', system-ui, -apple-system, sans-serif;
          color: var(--text-1);
          background: var(--surface-2);
          border-radius: var(--radius-lg);
          overflow: hidden;
          box-shadow: 0 8px 24px rgba(26,24,22,0.08);
        }

        /* ═══ Frame Bar ═══ */
        .frame-bar {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          padding: 0.75rem 1rem;
          background: #1e1e2a;
          color: white;
        }
        .frame-title { font-size: 0.8125rem; color: rgba(255,255,255,0.6); font-weight: 500; }
        .frame-time { margin-left: auto; font-size: 0.75rem; opacity: 0.7; }

        /* ═══ HUD Banner ═══ */
        .hud-banner {
          display: flex; flex-wrap: wrap; gap: 0.5rem;
          padding: 0.75rem 1rem;
          background: #1a1a24;
          border-bottom: 1px solid rgba(255,255,255,0.1);
        }
        .hud-alert {
          display: flex; align-items: center; gap: 0.5rem;
          padding: 0.5rem 0.75rem; border-radius: 6px;
          font-size: 0.75rem; flex-shrink: 0;
        }
        .hud-alert svg { flex-shrink: 0; }
        .hud-alert.urgent { background: rgba(224,93,80,0.2); color: #f0a8a0; border: 1px solid rgba(224,93,80,0.4); }
        .hud-alert.urgent svg { color: var(--coral); }
        .hud-alert.schedule { background: rgba(192,139,48,0.15); color: #e8c97a; border: 1px solid rgba(192,139,48,0.3); }
        .hud-alert.schedule svg { color: var(--amber); }
        .hud-alert.sub { background: rgba(124,95,196,0.15); color: #c4b5e8; border: 1px solid rgba(124,95,196,0.3); }
        .hud-alert.sub svg { color: var(--purple); }
        .hud-text { white-space: nowrap; }
        .hud-text strong { font-weight: 600; }
        .hud-badge {
          font-size: 0.625rem; font-weight: 600; text-transform: uppercase;
          letter-spacing: 0.04em; padding: 0.125rem 0.375rem; border-radius: 3px;
          background: rgba(42,157,143,0.3); color: #80d0c8; margin-left: 0.25rem;
        }

        /* ═══ 3-Column Layout ═══ */
        .classroom-dashboard {
          display: grid;
          grid-template-columns: 220px 320px 1fr;
          flex: 1;
          overflow: hidden;
        }

        /* ═══ Column 1: Roster ═══ */
        .cd-roster { background: #2c2c2e; color: white; overflow-y: auto; }
        .cd-col-header {
          display: flex; justify-content: space-between; align-items: center;
          padding: 0.875rem 1rem; border-bottom: 1px solid rgba(255,255,255,0.1);
          position: sticky; top: 0; background: #2c2c2e; z-index: 2;
        }
        .cd-col-title { font-size: 0.875rem; font-weight: 600; margin: 0; }
        .cd-col-count { font-size: 0.6875rem; color: rgba(255,255,255,0.5); }
        .roster-section { padding: 0.5rem 0; }
        .roster-label {
          display: flex; align-items: center; justify-content: space-between;
          padding: 0.5rem 1rem; font-size: 0.625rem;
          text-transform: uppercase; letter-spacing: 0.06em; color: rgba(255,255,255,0.4);
        }
        .roster-location { display: flex; align-items: center; gap: 0.375rem; }
        .roster-location svg { color: var(--teal); }
        .roster-location.away svg { color: var(--amber); }
        .roster-location.absent svg { color: var(--coral); }
        .roster-count { font-weight: 600; }

        .roster-student {
          display: flex; align-items: center; gap: 0.625rem;
          padding: 0.5rem 1rem; cursor: pointer; transition: background 0.15s;
          border: none; background: transparent; width: 100%;
          text-align: left; color: white; font: inherit;
        }
        .roster-student:hover { background: rgba(255,255,255,0.05); }
        .roster-student.selected { background: rgba(42,157,143,0.2); }
        .roster-student.away { opacity: 0.6; }
        .roster-student.absent-row { opacity: 0.4; }

        .rs-avatar { width: 32px; height: 32px; border-radius: 8px; overflow: hidden; position: relative; flex-shrink: 0; }
        .rs-avatar img { width: 100%; height: 100%; object-fit: cover; border-radius: 8px; }
        .rs-status {
          position: absolute; bottom: -1px; right: -1px;
          width: 10px; height: 10px; border-radius: 50%; border: 2px solid #2c2c2e;
        }
        .rs-status.present { background: var(--teal); }
        .rs-status.away { background: var(--amber); }
        .rs-status.absent { background: var(--coral); }

        .rs-info { flex: 1; min-width: 0; }
        .rs-name { display: block; font-size: 0.8125rem; font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .rs-tags { display: flex; gap: 0.25rem; margin-top: 0.125rem; }
        .rs-tag { font-size: 0.5rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.04em; padding: 0.125rem 0.25rem; border-radius: 2px; }
        .rs-tag.iep { background: rgba(124,95,196,0.3); color: #b8a5e0; }
        .rs-tag.allergy { background: rgba(224,93,80,0.3); color: #f0a8a0; }
        .rs-tag.plan { background: rgba(42,157,143,0.3); color: #80d0c8; }
        .rs-location { display: block; font-size: 0.6875rem; color: var(--amber); }
        .rs-reason { display: block; font-size: 0.6875rem; color: rgba(255,255,255,0.4); }
        .rs-return { display: block; font-size: 0.625rem; color: rgba(255,255,255,0.4); }
        .rs-staff { flex-shrink: 0; }

        .staff-avatar-mini {
          width: 20px; height: 20px; border-radius: 5px;
          display: flex; align-items: center; justify-content: center;
          font-size: 0.5rem; font-weight: 700; color: white;
        }
        .staff-avatar-mini.teal { background: var(--teal); }
        .staff-avatar-mini.purple { background: var(--purple); }
        .staff-avatar-mini.coral { background: var(--coral); }
        .staff-avatar-mini.amber { background: var(--amber); }

        .staff-avatar-sm {
          width: 28px; height: 28px; border-radius: 7px;
          display: flex; align-items: center; justify-content: center;
          font-size: 0.625rem; font-weight: 700; color: white;
        }
        .staff-avatar-sm.teal { background: var(--teal); }
        .staff-avatar-sm.purple { background: var(--purple); }
        .staff-avatar-sm.coral { background: var(--coral); }
        .staff-avatar-sm.amber { background: var(--amber); }

        /* ═══ Column 2: Student Detail ═══ */
        .cd-daily { background: var(--surface-1); border-right: 1px solid var(--surface-2); overflow-y: auto; }
        .cd-student-header { padding: 1rem; background: var(--surface-0); border-bottom: 1px solid var(--surface-2); }
        .cd-student-id { display: flex; gap: 0.75rem; margin-bottom: 0.75rem; }
        .cd-student-avatar { width: 48px; height: 48px; border-radius: 12px; overflow: hidden; flex-shrink: 0; }
        .cd-student-avatar img { width: 100%; height: 100%; object-fit: cover; }
        .cd-student-name { font-size: 1.125rem; font-weight: 600; margin: 0; letter-spacing: -0.01em; }
        .cd-student-meta { font-size: 0.75rem; color: var(--text-3); }
        .cd-student-tags { display: flex; gap: 0.25rem; margin-top: 0.375rem; }
        .cd-tag { font-size: 0.5rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.04em; padding: 0.125rem 0.375rem; border-radius: 3px; }
        .cd-tag.iep { background: var(--purple-soft); color: var(--purple); }
        .cd-tag.allergy { background: var(--coral-soft); color: var(--coral); }
        .cd-tag.plan { background: var(--teal-soft); color: var(--teal); }

        .cd-student-staff {
          display: flex; align-items: center; gap: 0.5rem;
          padding-top: 0.75rem; border-top: 1px solid var(--surface-2);
        }
        .cd-staff-label { font-size: 0.625rem; color: var(--text-3); text-transform: uppercase; letter-spacing: 0.04em; }
        .cd-staff-assigned { display: flex; align-items: center; gap: 0.375rem; margin-left: auto; }
        .cd-staff-name { font-size: 0.75rem; font-weight: 500; }

        /* Alerts */
        .cd-alerts { padding: 0.75rem; display: flex; flex-direction: column; gap: 0.5rem; }
        .cd-alert { display: flex; align-items: flex-start; gap: 0.5rem; padding: 0.625rem 0.75rem; border-radius: var(--radius-sm); font-size: 0.75rem; }
        .cd-alert.urgent { background: var(--coral-soft); color: var(--coral); }
        .cd-alert.note { background: var(--surface-0); color: var(--text-2); }
        .cd-alert-content { flex: 1; }
        .cd-alert-title { display: block; font-weight: 600; font-size: 0.625rem; text-transform: uppercase; letter-spacing: 0.04em; margin-bottom: 0.125rem; }
        .cd-alert-text { display: block; line-height: 1.3; }

        /* Plan/Schedule */
        .cd-plan { padding: 0.75rem; }
        .cd-section-title {
          font-size: 0.625rem; font-weight: 700; text-transform: uppercase;
          letter-spacing: 0.08em; color: var(--text-3); margin: 0 0 0.625rem;
          display: flex; align-items: center; gap: 0.375rem;
        }
        .cd-section-badge { background: var(--surface-2); padding: 0.125rem 0.375rem; border-radius: 100px; font-weight: 500; }
        .cd-schedule { display: flex; flex-direction: column; gap: 0.125rem; }
        .cd-sched-item { display: grid; grid-template-columns: 36px 10px 1fr; gap: 0.5rem; align-items: center; padding: 0.375rem 0; }
        .cd-sched-time { font-size: 0.6875rem; font-weight: 500; color: var(--text-3); text-align: right; }
        .cd-sched-dot { width: 8px; height: 8px; border-radius: 50%; background: var(--surface-3); }
        .cd-sched-item.done .cd-sched-dot { background: var(--teal); }
        .cd-sched-item.current .cd-sched-dot { background: var(--coral); box-shadow: 0 0 0 3px var(--coral-soft); }
        .cd-sched-item.current .cd-sched-time { color: var(--coral); font-weight: 600; }
        .cd-sched-content { display: flex; align-items: center; justify-content: space-between; gap: 0.5rem; }
        .cd-sched-activity { font-size: 0.75rem; }
        .cd-sched-item.done .cd-sched-activity { color: var(--text-3); }
        .cd-sched-item.current .cd-sched-activity { font-weight: 600; }
        .cd-sched-result { font-size: 0.625rem; font-weight: 600; }
        .cd-sched-result.good { color: var(--teal); }
        .cd-sched-tag {
          font-size: 0.5rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.04em;
          padding: 0.125rem 0.375rem; border-radius: 3px;
          background: var(--coral-soft); color: var(--coral);
        }
        .cd-sched-tag.goal { background: var(--purple-soft); color: var(--purple); }

        /* Goals */
        .cd-goals { padding: 0.75rem; border-top: 1px solid var(--surface-2); }
        .cd-goal-cards { display: flex; flex-direction: column; gap: 0.5rem; }
        .cd-goal-card { padding: 0.625rem; background: var(--surface-0); border-radius: var(--radius-sm); }
        .cd-gc-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.25rem; }
        .cd-gc-domain { font-size: 0.5rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em; }
        .cd-gc-domain.coral { color: var(--coral); }
        .cd-gc-domain.purple { color: var(--purple); }
        .cd-gc-domain.amber { color: var(--amber); }
        .cd-gc-domain.teal { color: var(--teal); }
        .cd-gc-pct { font-size: 0.6875rem; font-weight: 700; color: var(--teal); }
        .cd-gc-title { display: block; font-size: 0.75rem; margin-bottom: 0.375rem; }
        .cd-gc-track { height: 4px; background: var(--surface-2); border-radius: 2px; overflow: hidden; }
        .cd-gc-fill { height: 100%; background: var(--teal); border-radius: 2px; }

        /* ═══ Column 3: Activity Feed ═══ */
        .cd-feed { background: var(--surface-0); display: flex; flex-direction: column; overflow: hidden; }

        /* Quick Entry */
        .cd-quick-entry { padding: 1rem; border-bottom: 1px solid var(--surface-2); background: var(--surface-0); }
        .qe-input-row { display: flex; gap: 0.625rem; margin-bottom: 0.625rem; }
        .qe-avatar { flex-shrink: 0; }
        .qe-textarea {
          flex: 1; min-height: 56px; padding: 0.625rem;
          border: 1px solid var(--surface-3); border-radius: var(--radius-sm);
          font-family: inherit; font-size: 0.875rem; resize: none;
          background: var(--surface-1); color: var(--text-1);
        }
        .qe-textarea:focus { outline: none; border-color: var(--coral); background: var(--surface-0); }
        .qe-actions { display: flex; justify-content: space-between; align-items: center; }
        .qe-attach { display: flex; gap: 0.25rem; }
        .qe-attach-btn {
          width: 32px; height: 32px; border-radius: var(--radius-sm);
          border: 1px solid var(--surface-3); background: var(--surface-0);
          color: var(--text-3); cursor: pointer;
          display: flex; align-items: center; justify-content: center;
          transition: border-color 0.15s, color 0.15s;
        }
        .qe-attach-btn:hover { border-color: var(--coral); color: var(--coral); }
        .qe-submit {
          display: flex; align-items: center; gap: 0.375rem;
          padding: 0.5rem 1rem; border-radius: var(--radius-sm);
          border: none; background: var(--coral); color: white;
          font-family: inherit; font-size: 0.875rem; font-weight: 600;
          cursor: pointer; transition: background 0.15s, transform 0.1s;
        }
        .qe-submit:hover { background: #cf5349; }
        .qe-submit:active { transform: scale(0.97); }
        .qe-hint { display: flex; align-items: center; gap: 0.375rem; margin-top: 0.5rem; font-size: 0.6875rem; color: var(--text-3); }

        /* Entry Type Selector */
        .qe-type-selector { display: flex; gap: 0.25rem; margin-bottom: 0.625rem; }
        .type-btn {
          padding: 0.375rem 0.75rem; border-radius: var(--radius-sm);
          border: 1px solid var(--surface-3); background: var(--surface-1);
          font-family: inherit; font-size: 0.75rem; font-weight: 500;
          color: var(--text-3); cursor: pointer; transition: all 0.15s;
        }
        .type-btn:hover { border-color: var(--text-3); color: var(--text-2); }
        .type-btn.active { border-color: var(--coral); background: var(--coral-soft); color: var(--coral); font-weight: 600; }

        /* Local Entry Badge */
        .cd-entry.local-entry { border: 1px dashed var(--amber); }
        .cd-entry-local-badge {
          display: inline-block; padding: 0.125rem 0.5rem;
          background: var(--amber-soft); color: var(--amber);
          font-size: 0.5625rem; font-weight: 700; text-transform: uppercase;
          letter-spacing: 0.04em; border-radius: 0 0 var(--radius-sm) var(--radius-sm);
          margin: 0 0.75rem;
        }

        /* Feed Header */
        .cd-feed-header {
          display: flex; justify-content: space-between; align-items: center;
          padding: 0.75rem 1rem; border-bottom: 1px solid var(--surface-2);
        }
        .cd-feed-count { font-size: 0.6875rem; color: var(--text-3); }

        /* Feed Entries */
        .cd-feed-entries { flex: 1; overflow-y: auto; padding: 0.75rem; display: flex; flex-direction: column; gap: 0.75rem; }
        .cd-entry { background: var(--surface-1); border-radius: var(--radius-sm); overflow: hidden; }
        .cd-entry.ai-processed { border: 1px solid var(--teal); }
        .cd-entry-ai {
          display: flex; align-items: center; gap: 0.75rem;
          padding: 0.5rem 0.75rem; background: var(--teal-soft); flex-wrap: wrap;
        }
        .ai-badge { display: flex; align-items: center; gap: 0.25rem; font-size: 0.5625rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.04em; color: var(--teal); }
        .ai-suggestion { display: flex; align-items: center; gap: 0.5rem; flex: 1; }
        .ai-type { font-size: 0.5625rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.04em; padding: 0.125rem 0.375rem; border-radius: 3px; }
        .ai-type.social { background: var(--purple-soft); color: var(--purple); }
        .ai-type.academic { background: var(--coral-soft); color: var(--coral); }
        .ai-type.behavioral { background: var(--amber-soft); color: var(--amber); }
        .ai-goal { font-size: 0.6875rem; color: var(--purple); }
        .ai-actions { display: flex; gap: 0.25rem; }
        .ai-accept, .ai-edit { padding: 0.25rem 0.5rem; border-radius: 4px; border: none; font-family: inherit; font-size: 0.6875rem; font-weight: 500; cursor: pointer; }
        .ai-accept { background: var(--teal); color: white; }
        .ai-edit { background: var(--surface-0); color: var(--text-2); }

        .cd-entry-content { padding: 0.75rem; }
        .cd-entry-header { display: flex; align-items: center; gap: 0.375rem; margin-bottom: 0.375rem; }
        .cd-entry-author { font-size: 0.75rem; font-weight: 600; }
        .cd-entry-time { font-size: 0.625rem; color: var(--text-3); margin-left: auto; }
        .cd-entry-text { font-size: 0.8125rem; line-height: 1.5; color: var(--text-2); margin: 0; }
        .cd-entry-tags { display: flex; align-items: center; gap: 0.5rem; margin-top: 0.5rem; flex-wrap: wrap; }
        .cd-entry-type { font-size: 0.5rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.04em; padding: 0.125rem 0.375rem; border-radius: 3px; }
        .cd-entry-type.academic { background: var(--coral-soft); color: var(--coral); }
        .cd-entry-type.social { background: var(--purple-soft); color: var(--purple); }
        .cd-entry-type.behavioral { background: var(--amber-soft); color: var(--amber); }
        .cd-entry-goal { font-size: 0.6875rem; color: var(--purple); }
        .cd-entry-score { font-size: 0.6875rem; font-weight: 600; }
        .cd-entry-score.good { color: var(--teal); }
        .cd-entry-flag {
          margin-top: 0.375rem; padding: 0.375rem 0.5rem;
          background: var(--amber-soft); border-left: 2px solid var(--amber);
          border-radius: 3px; font-size: 0.6875rem; color: var(--text-2);
        }

        /* ═══ Shared ═══ */
        .empty-state { padding: 2rem; text-align: center; color: var(--text-3); font-size: 0.8125rem; font-style: italic; }
      </style>
    </template>
  };

  static embedded = class Embedded extends Component<typeof Classroom> {
    get safeName() { return this.args.model?.classroomName ?? 'Classroom'; }
    get teacherName() { return this.args.model?.teacher?.name ?? ''; }
    get studentCount() { return this.args.model?.students?.length ?? 0; }

    <template>
      <div class='ce'>
        <div class='ce-info'>
          <div class='ce-name'>{{this.safeName}}</div>
          {{#if this.teacherName}}<div class='ce-teacher'>{{this.teacherName}}</div>{{/if}}
        </div>
        <span class='ce-count'>{{this.studentCount}} students</span>
      </div>
      <style scoped>
        .ce { display: flex; align-items: center; justify-content: space-between; gap: 0.5rem; padding: 0.75rem 1rem; background: var(--card); border: 1px solid var(--border); border-radius: var(--boxel-border-radius); height: 100%; }
        .ce-name { font-weight: 700; font-size: var(--boxel-font-size); }
        .ce-teacher { font-size: var(--boxel-font-size-xs); color: var(--muted-foreground); }
        .ce-count { font-size: var(--boxel-font-size-xs); color: var(--muted-foreground); }
      </style>
    </template>
  };

  static edit = class Edit extends Component<typeof Classroom> {
    <template>
      <div class='card-edit'>
        <div class='field-row'>
          <label>Classroom Name</label>
          <@fields.classroomName />
        </div>
        <div class='field-row'>
          <label>Teacher</label>
          <@fields.teacher />
        </div>
        <div class='field-row'>
          <label>Date</label>
          <@fields.date />
        </div>
      </div>

      <style scoped>
        .card-edit {
          display: flex;
          flex-direction: column;
          gap: var(--boxel-sp-sm);
          padding: var(--boxel-sp-sm);
          border: 1px solid var(--border);
          border-radius: var(--boxel-border-radius);
        }

        .field-row {
          display: flex;
          flex-direction: column;
          gap: 0.25rem;
        }

        .field-row label {
          font-size: var(--boxel-font-size-xs);
          font-weight: 600;
          color: var(--muted-foreground);
          text-transform: uppercase;
          letter-spacing: 0.05em;
        }
      </style>
    </template>
  };

  static fitted = class Fitted extends Component<typeof Classroom> {
    get safeName() { return this.args.model?.classroomName ?? 'Classroom'; }

    <template>
      <div class='fitted-container'>
        <div class='tile'>
          <span class='tile-name'>{{this.safeName}}</span>
        </div>
      </div>
      <style scoped>
        .fitted-container { container-type: size; width: 100%; height: 100%; }
        .tile { display: flex; align-items: center; justify-content: center; padding: var(--boxel-sp); background: var(--card); border: 1px solid var(--border); border-radius: var(--boxel-border-radius); height: 100%; }
        .tile-name { font-weight: 700; font-size: var(--boxel-font-size); text-align: center; }
      </style>
    </template>
  };
}
